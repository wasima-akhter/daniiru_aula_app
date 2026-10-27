import 'package:aula360/core/constants/api_constants.dart';
import 'package:aula360/core/network/api_client.dart';
import 'package:aula360/features/parent_all/data/datasources/parent_remote_data_source.dart';
import 'package:aula360/features/parent_all/data/dtos/announcement_dto.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/domain/repositories/parent_repository.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_announcements_controller.dart';
import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends Fake implements ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;

    if (path == ApiConstants.announcements) {
      final page = queryParameters?['page'] ?? 1;
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Announcements retrieved successfully',
          'traceId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
          'meta': {
            'total': 25,
            'totalPages': 3,
            'links': {
              'currentPage':
                  'http://localhost:5006/api/v1/announcements?page=$page&limit=10',
              'nextPage': page < 3
                  ? 'http://localhost:5006/api/v1/announcements?page=${page + 1}&limit=10'
                  : null,
              'previousPage': page > 1
                  ? 'http://localhost:5006/api/v1/announcements?page=${page - 1}&limit=10'
                  : null,
              'firstPage':
                  'http://localhost:5006/api/v1/announcements?page=1&limit=10',
              'lastPage':
                  'http://localhost:5006/api/v1/announcements?page=3&limit=10',
            },
          },
          'data': [
            {
              'id': 'parent-announcement-$page',
              'title': 'School Activity Page $page',
              'body': 'Important update for parents regarding page $page activities',
              'audience': 'PARENTS',
              'createdById': 'admin-uuid-1',
              'publishedAt': '2026-10-25T08:00:00.000Z',
              'createdAt': '2026-10-25T08:00:00.000Z',
            }
          ],
        } as dynamic,
      );
    }

    throw UnimplementedError('No mock for $path');
  }
}

class _FakeParentRepository extends Fake implements ParentRepository {
  int getAnnouncementsCallCount = 0;
  int? lastPage;
  int? lastLimit;

  @override
  Future<PaginatedResult<AnnouncementDto>> getAnnouncements({
    int page = 1,
    int limit = 10,
  }) async {
    getAnnouncementsCallCount++;
    lastPage = page;
    lastLimit = limit;

    return PaginatedResult<AnnouncementDto>(
      data: [
        AnnouncementDto(
          id: 'parent-item-$page',
          title: 'Parent Notice $page',
          body: 'Body for notice $page',
          audience: 'PARENTS',
          publishedAt: '2026-10-25T08:00:00.000Z',
        ),
      ],
      meta: null,
    );
  }
}

void main() {
  group('Parent Announcements Tests', () {
    test('AnnouncementDto parses Parent API JSON correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174999',
        'title': 'Parent-Teacher Meeting Notice',
        'body': 'Meeting scheduled for Friday at 4 PM in Auditorium.',
        'audience': 'PARENTS',
        'createdById': '123e4567-e89b-12d3-a456-426614174888',
        'publishedAt': '2026-10-25T10:00:00.000Z',
        'createdAt': '2026-10-25T10:00:00.000Z',
      };

      final dto = AnnouncementDto.fromJson(json);

      expect(dto.id, '123e4567-e89b-12d3-a456-426614174999');
      expect(dto.title, 'Parent-Teacher Meeting Notice');
      expect(dto.body, 'Meeting scheduled for Friday at 4 PM in Auditorium.');
      expect(dto.audience, 'PARENTS');
      expect(dto.createdById, '123e4567-e89b-12d3-a456-426614174888');
      expect(dto.publishedAt, '2026-10-25T10:00:00.000Z');
      expect(dto.createdAt, '2026-10-25T10:00:00.000Z');
    });

    test('ParentRemoteDataSourceImpl getAnnouncements calls GET /announcements with query params', () async {
      final fakeApi = _FakeApiClient();
      final dataSource = ParentRemoteDataSourceImpl(fakeApi);

      final result = await dataSource.getAnnouncements(page: 2, limit: 10);

      expect(fakeApi.lastPath, ApiConstants.announcements);
      expect(fakeApi.lastQueryParams?['page'], 2);
      expect(fakeApi.lastQueryParams?['limit'], 10);
      expect(result.items.length, 1);
      expect(result.items.first.id, 'parent-announcement-2');
      expect(result.items.first.title, 'School Activity Page 2');
      expect(result.items.first.audience, 'PARENTS');
    });

    test('ParentRepositoryImpl getAnnouncements delegates to parentRemoteDataSource', () async {
      final fakeApi = _FakeApiClient();
      final dataSource = ParentRemoteDataSourceImpl(fakeApi);
      final repo = ParentRepositoryImpl(parentRemoteDataSource: dataSource);

      final result = await repo.getAnnouncements(page: 1, limit: 10);

      expect(result.items.length, 1);
      expect(result.items.first.id, 'parent-announcement-1');
      expect(result.items.first.audience, 'PARENTS');
    });

    test('ParentAnnouncementsController loads announcements and supports refresh and loadMore', () async {
      final fakeRepo = _FakeParentRepository();
      final container = ProviderContainer(
        overrides: [
          parentRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(parentAnnouncementsControllerProvider.notifier);

      // Trigger initial load
      await controller.loadAnnouncements();

      var state = container.read(parentAnnouncementsControllerProvider);
      expect(state.isLoading, false);
      expect(state.announcements.length, 1);
      expect(state.announcements.first.id, 'parent-item-1');

      // Trigger load more
      await controller.loadMore();

      state = container.read(parentAnnouncementsControllerProvider);
      expect(state.announcements.length, 2);
      expect(state.announcements[1].id, 'parent-item-2');
      expect(state.currentPage, 2);

      // Trigger refresh
      await controller.refresh();

      state = container.read(parentAnnouncementsControllerProvider);
      expect(state.currentPage, 1);
      expect(state.announcements.length, 1);
      expect(state.announcements.first.id, 'parent-item-1');
    });
  });
}

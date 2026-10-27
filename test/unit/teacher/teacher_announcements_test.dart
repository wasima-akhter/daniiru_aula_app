import 'package:aula360/core/constants/api_constants.dart';
import 'package:aula360/core/network/api_client.dart';
import 'package:aula360/features/parent_all/data/dtos/announcement_dto.dart';
import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:aula360/features/teacher_all/announcements/presentation/controllers/teacher_announcements_controller.dart';
import 'package:aula360/features/teacher_all/data/datasources/teacher_remote_data_source.dart';
import 'package:aula360/features/teacher_all/data/repositories/teacher_repository_impl.dart';
import 'package:aula360/features/teacher_all/domain/repositories/teacher_repository.dart';
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
              'currentPage': 'http://localhost:5006/api/v1/announcements?page=$page&limit=10',
              'nextPage': page < 3 ? 'http://localhost:5006/api/v1/announcements?page=${page + 1}&limit=10' : null,
              'previousPage': page > 1 ? 'http://localhost:5006/api/v1/announcements?page=${page - 1}&limit=10' : null,
              'firstPage': 'http://localhost:5006/api/v1/announcements?page=1&limit=10',
              'lastPage': 'http://localhost:5006/api/v1/announcements?page=3&limit=10',
            },
          },
          'data': [
            {
              'id': 'announcement-id-$page',
              'title': 'Academy Notice Page $page',
              'body': 'Details for announcement on page $page',
              'audience': 'TEACHERS',
              'createdById': 'creator-uuid-1',
              'publishedAt': '2026-10-22T08:00:00.000Z',
              'createdAt': '2026-10-22T08:00:00.000Z',
            }
          ],
        } as dynamic,
      );
    }

    throw UnimplementedError('No mock for $path');
  }
}

class _FakeTeacherRepository extends Fake implements TeacherRepository {
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
          id: 'item-$page',
          title: 'Title $page',
          body: 'Body $page',
          audience: 'TEACHERS',
          publishedAt: '2026-10-22T08:00:00.000Z',
        ),
      ],
      meta: null,
    );
  }
}

void main() {
  group('Teacher Announcements Tests', () {
    test('AnnouncementDto parses API JSON correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Academy Winter Break Notice',
        'body': 'Please note that the academy will be closed from Dec 24 to Jan 2.',
        'audience': 'TEACHERS',
        'createdById': '123e4567-e89b-12d3-a456-426614174001',
        'publishedAt': '2026-10-22T08:00:00.000Z',
        'createdAt': '2026-10-22T08:00:00.000Z',
      };

      final dto = AnnouncementDto.fromJson(json);

      expect(dto.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(dto.title, 'Academy Winter Break Notice');
      expect(dto.body, 'Please note that the academy will be closed from Dec 24 to Jan 2.');
      expect(dto.audience, 'TEACHERS');
      expect(dto.createdById, '123e4567-e89b-12d3-a456-426614174001');
      expect(dto.publishedAt, '2026-10-22T08:00:00.000Z');
      expect(dto.createdAt, '2026-10-22T08:00:00.000Z');
    });

    test('TeacherRemoteDataSourceImpl getAnnouncements calls GET /announcements with query params', () async {
      final fakeApi = _FakeApiClient();
      final dataSource = TeacherRemoteDataSourceImpl(fakeApi);

      final result = await dataSource.getAnnouncements(page: 2, limit: 10);

      expect(fakeApi.lastPath, ApiConstants.announcements);
      expect(fakeApi.lastQueryParams?['page'], 2);
      expect(fakeApi.lastQueryParams?['limit'], 10);
      expect(result.items.length, 1);
      expect(result.items.first.id, 'announcement-id-2');
      expect(result.items.first.title, 'Academy Notice Page 2');
      expect(result.items.first.audience, 'TEACHERS');
    });

    test('TeacherRepositoryImpl getAnnouncements delegates to remoteDataSource', () async {
      final fakeApi = _FakeApiClient();
      final dataSource = TeacherRemoteDataSourceImpl(fakeApi);
      final repo = TeacherRepositoryImpl(remoteDataSource: dataSource);

      final result = await repo.getAnnouncements(page: 1, limit: 10);

      expect(result.items.length, 1);
      expect(result.items.first.id, 'announcement-id-1');
      expect(result.items.first.audience, 'TEACHERS');
    });

    test('TeacherAnnouncementsController loads announcements and supports refresh and loadMore', () async {
      final fakeRepo = _FakeTeacherRepository();
      final container = ProviderContainer(
        overrides: [
          teacherRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(teacherAnnouncementsControllerProvider.notifier);

      // Trigger initial load
      await controller.loadAnnouncements();

      var state = container.read(teacherAnnouncementsControllerProvider);
      expect(state.isLoading, false);
      expect(state.announcements.length, 1);
      expect(state.announcements.first.id, 'item-1');

      // Trigger load more
      await controller.loadMore();

      state = container.read(teacherAnnouncementsControllerProvider);
      expect(state.announcements.length, 2);
      expect(state.announcements[1].id, 'item-2');
      expect(state.currentPage, 2);

      // Trigger refresh
      await controller.refresh();

      state = container.read(teacherAnnouncementsControllerProvider);
      expect(state.currentPage, 1);
      expect(state.announcements.length, 1);
      expect(state.announcements.first.id, 'item-1');
    });
  });
}

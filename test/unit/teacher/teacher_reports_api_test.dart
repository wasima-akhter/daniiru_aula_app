import 'package:aula360/core/constants/api_constants.dart';
import 'package:aula360/core/network/api_client.dart';
import 'package:aula360/features/teacher_all/data/datasources/teacher_remote_data_source.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/reports/data/dtos/teacher_report_dto.dart';
import 'package:aula360/features/teacher_all/reports/data/repositories/teacher_reports_repository_impl.dart';
import 'package:aula360/features/teacher_all/reports/presentation/controllers/teacher_reports_controller.dart';
import 'package:aula360/features/teacher_all/reports/presentation/providers/teacher_reports_providers.dart';
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

    if (path == ApiConstants.teacherReports) {
      final status = queryParameters?['status'];
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Class reports retrieved successfully',
          'meta': {'total': 1, 'totalPages': 1},
          'data': [
            {
              'id': '123e4567-e89b-12d3-a456-426614174000',
              'sessionId': '123e4567-e89b-12d3-a456-426614174001',
              'sessionDate': '2026-10-25T14:00:00.000Z',
              'cohortId': '123e4567-e89b-12d3-a456-426614174002',
              'cohortName': 'Grade 10 - Mathematics Cohort A',
              'subjectId': '123e4567-e89b-12d3-a456-426614174003',
              'subjectName': 'Advanced Mathematics',
              'contentCovered':
                  'Chapter 4: Quadratic Equations - Factoring and Quadratic Formula',
              'homeworkAssigned': 'Exercise 4.2 questions 1-15 odd only',
              'attitudeRating': 'SATISFACTORY',
              'workEffortRating': 'ON_TRACK',
              'observations':
                  'Students engaged well with the quadratic formula proofs.',
              'status': status ?? 'SUBMITTED',
              'submittedAt': '2026-10-25T15:30:00.000Z',
              'reviewedAt': null,
              'reviewNote': null,
            }
          ]
        } as dynamic,
      );
    }

    if (path.startsWith('${ApiConstants.teacherReports}/')) {
      final id = path.split('/').last;
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Class report details retrieved successfully',
          'data': {
            'id': id,
            'sessionId': '123e4567-e89b-12d3-a456-426614174001',
            'sessionDate': '2026-10-25T14:00:00.000Z',
            'cohortId': '123e4567-e89b-12d3-a456-426614174002',
            'cohortName': 'Grade 10 - Mathematics Cohort A',
            'subjectId': '123e4567-e89b-12d3-a456-426614174003',
            'subjectName': 'Advanced Mathematics',
            'contentCovered':
                'Chapter 4: Quadratic Equations - Factoring and Quadratic Formula',
            'homeworkAssigned': 'Exercise 4.2 questions 1-15 odd only',
            'attitudeRating': 'SATISFACTORY',
            'workEffortRating': 'ON_TRACK',
            'observations':
                'Students engaged well with the quadratic formula proofs.',
            'status': 'SUBMITTED',
            'submittedAt': '2026-10-25T15:30:00.000Z',
            'reviewedAt': null,
            'reviewNote': null,
            'startTime': '09:00',
            'endTime': '10:30',
            'entryTime': '2026-10-25T09:02:15.000Z',
            'exitTime': '2026-10-25T10:29:45.000Z',
            'attendances': [
              {
                'studentId': '123e4567-e89b-12d3-a456-426614174010',
                'studentName': 'Leo Jenkins',
                'avatarUrl': 'https://cdn.alua.edu/avatars/leo.jpg',
                'status': 'PRESENT',
              }
            ],
            'attendanceSummary': {
              'total': 24,
              'present': 22,
              'absent': 1,
              'late': 1,
              'excused': 0,
            },
          }
        } as dynamic,
      );
    }

    throw UnimplementedError('Path $path not mocked');
  }
}

void main() {
  group('TeacherReport DTOs', () {
    test('TeacherReportDto parsing and toModel() mapping', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'sessionId': '123e4567-e89b-12d3-a456-426614174001',
        'sessionDate': '2026-10-25T14:00:00.000Z',
        'cohortId': '123e4567-e89b-12d3-a456-426614174002',
        'cohortName': 'Grade 10 - Mathematics Cohort A',
        'subjectId': '123e4567-e89b-12d3-a456-426614174003',
        'subjectName': 'Advanced Mathematics',
        'contentCovered': 'Quadratic Formula',
        'homeworkAssigned': 'Exercise 4.2',
        'attitudeRating': 'SATISFACTORY',
        'workEffortRating': 'ON_TRACK',
        'observations': 'Great engagement',
        'status': 'SUBMITTED',
        'submittedAt': '2026-10-25T15:30:00.000Z',
        'reviewedAt': null,
        'reviewNote': null,
      };

      final dto = TeacherReportDto.fromJson(json);
      expect(dto.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(dto.status, 'SUBMITTED');

      final model = dto.toModel();
      expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(model.title, 'Advanced Mathematics');
      expect(model.subtitle, 'Grade 10 - Mathematics Cohort A');
      expect(model.date, '2026-10-25');
      expect(model.status, ReportStatus.submitted);
      expect(model.contentCovered, 'Quadratic Formula');
      expect(model.homeworkAssigned, 'Exercise 4.2');
    });

    test('TeacherReportDetailDto parsing with attendances and summary', () {
      final json = {
        'id': 'rep-999',
        'sessionId': 'sess-1',
        'sessionDate': '2026-10-25T14:00:00.000Z',
        'cohortId': 'c-1',
        'cohortName': 'Grade 10 - Mathematics Cohort A',
        'subjectId': 'sub-1',
        'subjectName': 'Advanced Mathematics',
        'contentCovered': 'Chapter 4',
        'homeworkAssigned': 'Exercise 4.2',
        'attitudeRating': 'EXCELLENT',
        'workEffortRating': 'HIGH_EFFORT',
        'observations': 'Engaged well',
        'status': 'REVIEWED',
        'submittedAt': '2026-10-25T15:30:00.000Z',
        'reviewedAt': '2026-10-26T09:00:00.000Z',
        'reviewNote': 'Approved with praise',
        'startTime': '09:00',
        'endTime': '10:30',
        'entryTime': '2026-10-25T09:02:15.000Z',
        'exitTime': '2026-10-25T10:29:45.000Z',
        'attendances': [
          {
            'studentId': 'st-1',
            'studentName': 'Leo Jenkins',
            'avatarUrl': 'https://cdn.alua.edu/avatars/leo.jpg',
            'status': 'PRESENT',
          }
        ],
        'attendanceSummary': {
          'total': 24,
          'present': 22,
          'absent': 1,
          'late': 1,
          'excused': 0,
        },
      };

      final detailDto = TeacherReportDetailDto.fromJson(json);
      expect(detailDto.id, 'rep-999');
      expect(detailDto.startTime, '09:00');
      expect(detailDto.endTime, '10:30');
      expect(detailDto.attendances.length, 1);
      expect(detailDto.attendances.first.studentName, 'Leo Jenkins');
      expect(detailDto.attendanceSummary?.total, 24);
      expect(detailDto.attendanceSummary?.present, 22);

      final model = detailDto.toModel();
      expect(model.id, 'rep-999');
      expect(model.status, ReportStatus.reviewed);
      expect(model.time, '09:00 - 10:30');
      expect(model.attendances.length, 1);
      expect(model.attendanceSummary?.total, 24);
      expect(model.reviewNote, 'Approved with praise');
    });
  });

  group('TeacherReports Remote DataSource & Repository', () {
    late _FakeApiClient fakeApiClient;
    late TeacherRemoteDataSource remoteDataSource;
    late TeacherReportsRepositoryImpl repository;

    setUp(() {
      fakeApiClient = _FakeApiClient();
      remoteDataSource = TeacherRemoteDataSourceImpl(fakeApiClient);
      repository = TeacherReportsRepositoryImpl(remoteDataSource);
    });

    test('getReports hits endpoint with correct query parameters and returns models', () async {
      final reports = await repository.getReports(
        page: 1,
        limit: 20,
        status: 'SUBMITTED',
      );

      expect(fakeApiClient.lastPath, ApiConstants.teacherReports);
      expect(fakeApiClient.lastQueryParams?['page'], 1);
      expect(fakeApiClient.lastQueryParams?['limit'], 20);
      expect(fakeApiClient.lastQueryParams?['status'], 'SUBMITTED');
      expect(reports.length, 1);
      expect(reports.first.title, 'Advanced Mathematics');
      expect(reports.first.status, ReportStatus.submitted);
    });

    test('getReportDetail hits endpoint with report id and returns full model', () async {
      final report = await repository.getReportDetail('123e4567-e89b-12d3-a456-426614174000');

      expect(
        fakeApiClient.lastPath,
        ApiConstants.teacherReportDetail('123e4567-e89b-12d3-a456-426614174000'),
      );
      expect(report.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(report.attendances.length, 1);
      expect(report.attendances.first.studentName, 'Leo Jenkins');
      expect(report.attendanceSummary?.present, 22);
      expect(report.contentCovered, contains('Quadratic'));
    });
  });

  group('TeacherReports Controller & State', () {
    late _FakeApiClient fakeApiClient;
    late TeacherRemoteDataSource remoteDataSource;
    late TeacherReportsRepositoryImpl repository;
    late ProviderContainer container;

    setUp(() {
      fakeApiClient = _FakeApiClient();
      remoteDataSource = TeacherRemoteDataSourceImpl(fakeApiClient);
      repository = TeacherReportsRepositoryImpl(remoteDataSource);
      container = ProviderContainer(
        overrides: [
          teacherReportsRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('Controller loads reports and handles status filtering and search query', () async {
      final controller = container.read(teacherReportsControllerProvider.notifier);
      await controller.loadReports();

      var state = container.read(teacherReportsControllerProvider);
      expect(state.isLoading, false);
      expect(state.reports.length, 1);
      expect(state.filteredReports.length, 1);

      // Search by subject name
      controller.setSearchQuery('Advanced');
      state = container.read(teacherReportsControllerProvider);
      expect(state.filteredReports.length, 1);

      // Search by non-matching query
      controller.setSearchQuery('Chemistry');
      state = container.read(teacherReportsControllerProvider);
      expect(state.filteredReports.isEmpty, true);

      // Clear search
      controller.clearSearch();
      state = container.read(teacherReportsControllerProvider);
      expect(state.filteredReports.length, 1);

      // Status filter
      controller.setStatusFilter('REVIEWED');
      await controller.loadReports();
      state = container.read(teacherReportsControllerProvider);
      expect(fakeApiClient.lastQueryParams?['status'], 'REVIEWED');
    });

    test('teacherReportDetailProvider fetches report detail by id', () async {
      final detail = await container.read(
        teacherReportDetailProvider('123e4567-e89b-12d3-a456-426614174000').future,
      );

      expect(detail.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(detail.attendances.isNotEmpty, true);
      expect(detail.attendances.first.studentName, 'Leo Jenkins');
    });
  });
}

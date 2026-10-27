import 'package:aula360/core/constants/api_constants.dart';
import 'package:aula360/core/network/api_client.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/parent_all/data/datasources/parent_remote_data_source.dart';
import 'package:aula360/features/parent_all/domain/models/parent_models.dart';
import 'package:aula360/features/parent_all/data/dtos/child_report_dto.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/domain/repositories/parent_repository.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_children_controller.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_reports_controller.dart';
import 'package:aula360/features/parent_all/reports/parent_report_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockReportDetailApiClient extends ApiClient {
  MockReportDetailApiClient() : super(Dio());

  dynamic responseData;
  int statusCode = 200;
  String? lastGetPath;
  Map<String, dynamic>? lastGetParams;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    lastGetParams = queryParameters;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: responseData as T,
      statusCode: statusCode,
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting();
  });

  group('ChildReportDetailDto Tests', () {
    final sampleJson = {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'reportDate': '2026-10-20T00:00:00.000Z',
      'subjectName': 'Mathematics',
      'cohortName': 'Grade 10 - Alpha',
      'teacherName': 'Dr. John Doe',
      'classroomRoomNumber': 'Room 204',
      'startTime': '09:00',
      'endTime': '10:30',
      'contentCovered': 'Quadratic Equations',
      'homeworkAssigned': 'Complete exercises 1 to 10 on page 42',
      'observations': 'Great participation in class discussion.',
      'attitudeRating': 'SATISFACTORY',
      'workEffortRating': 'ON_TRACK',
      'studentAttendanceStatus': 'PRESENT',
      'submittedAt': '2026-10-20T11:00:00.000Z',
      'reviewedAt': '2026-10-20T12:00:00.000Z',
    };

    test('parses fromJson accurately matching API schema', () {
      final dto = ChildReportDetailDto.fromJson(sampleJson);

      expect(dto.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(dto.reportDate, '2026-10-20T00:00:00.000Z');
      expect(dto.subjectName, 'Mathematics');
      expect(dto.cohortName, 'Grade 10 - Alpha');
      expect(dto.teacherName, 'Dr. John Doe');
      expect(dto.classroomRoomNumber, 'Room 204');
      expect(dto.startTime, '09:00');
      expect(dto.endTime, '10:30');
      expect(dto.contentCovered, 'Quadratic Equations');
      expect(dto.homeworkAssigned, 'Complete exercises 1 to 10 on page 42');
      expect(dto.observations, 'Great participation in class discussion.');
      expect(dto.attitudeRating, 'SATISFACTORY');
      expect(dto.workEffortRating, 'ON_TRACK');
      expect(dto.studentAttendanceStatus, 'PRESENT');
      expect(dto.submittedAt, '2026-10-20T11:00:00.000Z');
      expect(dto.reviewedAt, '2026-10-20T12:00:00.000Z');
    });

    test('converts to ReportModel with formatted time and initials', () {
      final dto = ChildReportDetailDto.fromJson(sampleJson);
      final model = dto.toReportModel('en');

      expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(model.subject, 'Mathematics');
      expect(model.teacher, 'Dr. John Doe');
      expect(model.initials, 'DJ');
      expect(model.time, '09:00 - 10:30');
      expect(model.status, 'PRESENT');
      expect(model.note, contains('Quadratic Equations'));
      expect(model.note, contains('Observations: Great participation in class discussion.'));
    });

    test('toReportModel formats in Spanish when locale is es', () {
      final dto = ChildReportDetailDto.fromJson(sampleJson);
      final model = dto.toReportModel('es');

      expect(model.note, contains('Observaciones: Great participation in class discussion.'));
    });
  });

  group('ParentRemoteDataSource getChildReportDetail', () {
    test('calls ApiConstants.parentChildReportDetail with childId and reportId', () async {
      final mockClient = MockReportDetailApiClient();
      final dataSource = ParentRemoteDataSourceImpl(mockClient);

      mockClient.responseData = {
        'success': true,
        'message': 'Class report details retrieved successfully',
        'data': {
          'id': 'report-999',
          'reportDate': '2026-10-20T00:00:00.000Z',
          'subjectName': 'Physics',
          'cohortName': 'Grade 11 - Beta',
          'teacherName': 'Prof. Albert Einstein',
          'classroomRoomNumber': 'Lab 1',
          'startTime': '11:00',
          'endTime': '12:30',
          'contentCovered': 'Thermodynamics',
          'homeworkAssigned': 'Problems 1 to 5',
          'observations': 'Excellent focus.',
          'attitudeRating': 'EXCELLENT',
          'workEffortRating': 'HIGH_PERFORMANCE',
          'studentAttendanceStatus': 'PRESENT',
        },
      };

      const childId = 'child-111';
      const reportId = 'report-999';

      final result = await dataSource.getChildReportDetail(childId, reportId);

      expect(
        mockClient.lastGetPath,
        ApiConstants.parentChildReportDetail(childId, reportId),
      );
      expect(mockClient.lastGetPath, '/parent/children/child-111/reports/report-999');
      expect(result.id, 'report-999');
      expect(result.subjectName, 'Physics');
      expect(result.teacherName, 'Prof. Albert Einstein');
      expect(result.contentCovered, 'Thermodynamics');
    });
  });

  group('ParentRepositoryImpl getChildReportDetail', () {
    test('delegates to remote data source and returns ChildReportDetailDto', () async {
      final mockClient = MockReportDetailApiClient();
      final remoteDataSource = ParentRemoteDataSourceImpl(mockClient);
      final repo = ParentRepositoryImpl(parentRemoteDataSource: remoteDataSource);

      mockClient.responseData = {
        'success': true,
        'data': {
          'id': 'rep-abc',
          'reportDate': '2026-10-22T00:00:00.000Z',
          'subjectName': 'Chemistry',
          'teacherName': 'Marie Curie',
          'attitudeRating': 'SATISFACTORY',
          'workEffortRating': 'ON_TRACK',
          'studentAttendanceStatus': 'PRESENT',
        },
      };

      final detail = await repo.getChildReportDetail('c-1', 'rep-abc');
      expect(detail.id, 'rep-abc');
      expect(detail.subjectName, 'Chemistry');
      expect(detail.teacherName, 'Marie Curie');
    });
  });

  group('ReportDetailsScreen Widget Integration Tests', () {
    testWidgets('renders report detail by fetching params without passing whole model', (tester) async {
      final detailDto = ChildReportDetailDto(
        id: 'rep-456',
        reportDate: '2026-10-20T00:00:00.000Z',
        subjectName: 'Mathematics',
        cohortName: 'Grade 10 - Alpha',
        teacherName: 'Dr. John Doe',
        classroomRoomNumber: 'Room 204',
        startTime: '09:00',
        endTime: '10:30',
        contentCovered: 'Quadratic Equations',
        homeworkAssigned: 'Complete exercises 1 to 10 on page 42',
        observations: 'Great participation in class discussion.',
        attitudeRating: 'SATISFACTORY',
        workEffortRating: 'ON_TRACK',
        studentAttendanceStatus: 'PRESENT',
      );

      final container = ProviderContainer(
        overrides: [
          childReportDetailProvider(
            const ChildReportDetailParams(
              childId: 'child-123',
              reportId: 'rep-456',
            ),
          ).overrideWith((ref) => Future.value(detailDto)),
          parentChildrenControllerProvider.overrideWith(
            () => _MockParentChildrenController([
              const ChildModel(
                id: 'child-123',
                name: 'Leo Messi',
                grade: 'Grade 10',
                room: 'Room 204',
                imageUrl: '',
                parentTeacher: 'Dr. John Doe',
                attendance: 100.0,
                present: 20,
                absent: 0,
                late: 0,
              ),
            ]),
          ),
        ],
      );

      tester.view.physicalSize = const Size(375, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(
              home: ReportDetailsScreen(
                childId: 'child-123',
                reportId: 'rep-456',
              ),
            ),
          ),
        ),
      );

      // Settle async fetch
      await tester.pumpAndSettle();

      // Verify header contents
      expect(find.text('Mathematics'), findsWidgets);
      expect(find.text('Dr. John Doe'), findsWidgets);
      expect(find.text('Room 204'), findsWidgets);
      expect(find.text('Grade 10 - Alpha'), findsWidgets);

      // Verify Content Covered section
      expect(find.text('Quadratic Equations', skipOffstage: false), findsOneWidget);

      // Verify Homework section
      expect(
        find.text('Complete exercises 1 to 10 on page 42', skipOffstage: false),
        findsOneWidget,
      );

      // Verify Teacher Observation section
      expect(
        find.text('"Great participation in class discussion."', skipOffstage: false),
        findsOneWidget,
      );

      // Verify Duration calculation from 09:00 to 10:30 = 1h 30min
      expect(find.text('1h 30min', skipOffstage: false), findsOneWidget);

      // Scroll down to reveal download action
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Verify download button
      expect(find.byIcon(Icons.download_outlined), findsWidgets);
    });
  });
}

class _MockParentChildrenController extends ParentChildrenController {
  final List<ChildModel> initialChildren;
  _MockParentChildrenController(this.initialChildren);

  @override
  ParentChildrenState build() {
    return ParentChildrenState(
      children: initialChildren,
      selectedChild: initialChildren.isNotEmpty ? initialChildren.first : null,
    );
  }
}

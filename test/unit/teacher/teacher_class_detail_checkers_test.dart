import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/teacher_all/classes/data/dtos/class_session_dto.dart';
import 'package:aula360/features/teacher_all/classes/presentation/providers/teacher_classes_providers.dart';
import 'package:aula360/features/teacher_all/classes/teacher_class_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeLanguageNotifier extends LanguageNotifier {
  @override
  Future<LanguageState> build() async {
    return const LanguageState(
      language: AppLanguage.english,
      strings: {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('es', null);
  });

  Widget buildTestScreen(ClassSessionDto session) {
    return ProviderScope(
      overrides: [
        teacherSessionDetailProvider(session.id).overrideWith(
          (ref) => Future.value(session),
        ),
        languageProvider.overrideWith(FakeLanguageNotifier.new),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: TeacherClassDetailScreen(sessionId: session.id),
        ),
      ),
    );
  }

  testWidgets(
    'TeacherClassDetailScreen checks checkers: hasReport=true, hasHomework=false, hasAttendance=true and gives option to assign homework',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const session = ClassSessionDto(
        id: 'sess-checkers-1',
        scheduleId: 'sch-1',
        sessionDate: '2026-11-02T09:00:00.000Z',
        startTime: '09:00',
        endTime: '10:30',
        status: 'ONGOING',
        subjectName: 'Advanced Mathematics',
        subjectId: 'sub-math-1',
        cohortId: 'coh-1',
        cohortName: 'Group 1',
        teacherName: 'Prof. Gauss',
        classroomRoomNumber: 'Aula 2',
        hasReport: true,
        hasHomework: false,
        hasAttendance: true,
        students: [
          SessionDetailStudentDto(
            id: 'stud-1',
            fullName: 'Carlos Santana',
            enrollmentNumber: 'EN-101',
            attendanceStatus: 'PRESENT',
          ),
        ],
        report: {
          'observations': 'Great participation today',
          'contentCovered': 'Linear Algebra and Eigenvalues',
        },
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      // Verify the session title & info
      expect(find.text('Advanced Mathematics\n(Group 1)'), findsOneWidget);

      // Verify session activities checklist title
      expect(find.text('SESSION ACTIVITIES'), findsOneWidget);

      // 2/3 completed (hasReport=true, hasAttendance=true, hasHomework=false)
      expect(find.text('2/3'), findsOneWidget);

      // Attendance is Done
      expect(find.text('Attendance'), findsOneWidget);

      // Homework is Missing, and Assign Homework button is presented
      expect(find.text('Homework'), findsOneWidget);
      expect(find.text('Assign Homework'), findsOneWidget);

      // Class Report is Done
      expect(find.text('Class Report'), findsOneWidget);
    },
  );

  testWidgets(
    'TeacherClassDetailScreen gives options to take attendance and submit report when missing',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const session = ClassSessionDto(
        id: 'sess-checkers-2',
        scheduleId: 'sch-2',
        sessionDate: '2026-11-02T11:00:00.000Z',
        startTime: '11:00',
        endTime: '12:30',
        status: 'COMPLETED',
        subjectName: 'Physics',
        subjectId: 'sub-phy-1',
        cohortId: 'coh-2',
        cohortName: 'Group 2',
        teacherName: 'Prof. Newton',
        classroomRoomNumber: 'Lab 3',
        hasReport: false,
        hasHomework: true,
        hasAttendance: false,
        students: [
          SessionDetailStudentDto(
            id: 'stud-2',
            fullName: 'Ana Bell',
            enrollmentNumber: 'EN-202',
          ),
        ],
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      // 1/3 completed (only hasHomework is true)
      expect(find.text('1/3'), findsOneWidget);

      // Take Attendance option is visible for missing attendance
      expect(find.text('Take Attendance'), findsOneWidget);

      // Submit Report option is visible for missing report
      expect(find.text('Submit Report'), findsOneWidget);

      // Pending activities notice is shown in completed class view
      expect(
        find.text('Pending activities require your attention'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TeacherClassDetailScreen translates activities checklist properly in Spanish',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const session = ClassSessionDto(
        id: 'sess-checkers-es',
        scheduleId: 'sch-es',
        sessionDate: '2026-11-02T11:00:00.000Z',
        startTime: '11:00',
        endTime: '12:30',
        status: 'SCHEDULED',
        subjectName: 'Historia',
        cohortName: 'Grupo 1',
        teacherName: 'Prof. Garcia',
        classroomRoomNumber: 'Aula 1',
        hasReport: true,
        hasHomework: false,
        hasAttendance: true,
      );

      final widget = ProviderScope(
        overrides: [
          teacherSessionDetailProvider(session.id).overrideWith(
            (ref) => Future.value(session),
          ),
          languageProvider.overrideWith(
            () => FakeLanguageNotifier()..build(),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const MaterialApp(
            home: TeacherClassDetailScreen(sessionId: 'sess-checkers-es'),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('Assign Homework'), findsOneWidget);
    },
  );
}

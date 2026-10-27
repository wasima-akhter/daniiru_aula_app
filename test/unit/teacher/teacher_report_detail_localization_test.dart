import 'dart:convert';
import 'package:aula360/core/files/file_download_service.dart';
import 'package:aula360/core/files/file_providers.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/reports/data/dtos/teacher_report_dto.dart';
import 'package:aula360/features/teacher_all/reports/teacher_report_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aula360/features/auth/presentation/controllers/auth_controller.dart';

class FakeLanguageNotifier extends LanguageNotifier {
  final AppLanguage appLang;
  final Map<String, String> stringsMap;

  FakeLanguageNotifier(this.appLang, this.stringsMap);

  @override
  Future<LanguageState> build() async {
    return LanguageState(
      language: appLang,
      strings: stringsMap,
    );
  }
}

class FakeAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(user: null);
  }
}

class FakeFileDownloadService extends Fake implements FileDownloadService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> enStrings;
  late Map<String, String> esStrings;

  setUpAll(() async {
    final enJson = await rootBundle.loadString('assets/lang/en.json');
    final esJson = await rootBundle.loadString('assets/lang/es.json');
    enStrings = (json.decode(enJson) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v.toString()),
    );
    esStrings = (json.decode(esJson) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v.toString()),
    );
  });

  const mockReport = TeacherReport(
    id: 'report-uuid-1234',
    title: 'Mathematics Advanced',
    subtitle: 'Calculus and Limits',
    category: ReportCategory.classReport,
    group: StudentGroup.groupA,
    grade: 'Grade 10',
    room: 'Room 101',
    date: '26 Oct 2026',
    time: '10:00 - 11:30',
    status: ReportStatus.reviewed,
    rawStatus: 'REVIEWED',
    attitudeRating: 'SATISFACTORY',
    workEffortRating: 'ON_TRACK',
    contentCovered: 'Derivatives and Applications',
    homeworkAssigned: 'Exercise 1 to 10',
    observations: 'Good engagement from students.',
    entryTime: '2026-10-26T09:58:00.000Z',
    exitTime: '2026-10-26T11:32:00.000Z',
    reviewedAt: '2026-10-26T12:00:00.000Z',
    reviewNote: 'Well organized session.',
    attendanceSummary: TeacherReportAttendanceSummaryDto(
      total: 18,
      present: 15,
      absent: 1,
      late: 1,
      excused: 1,
    ),
    attendances: [
      TeacherReportStudentAttendanceDto(
        studentId: 'stud-1',
        studentName: 'Ana Garcia',
        status: 'PRESENT',
      ),
    ],
  );

  Widget buildScreen(AppLanguage lang, Map<String, String> strings) {
    return ProviderScope(
      overrides: [
        languageProvider.overrideWith(() => FakeLanguageNotifier(lang, strings)),
        fileDownloadServiceProvider.overrideWithValue(FakeFileDownloadService()),
        authControllerProvider.overrideWith(FakeAuthController.new),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => const MaterialApp(
          home: TeacherReportDetailsScreen(report: mockReport),
        ),
      ),
    );
  }

  testWidgets('displays all elements correctly in Spanish when Spanish is selected', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'es'});
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen(AppLanguage.spanish, esStrings));
    await tester.pumpAndSettle();

    // Faculty default fallback
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Docente Aula 360'),
      ),
      findsOneWidget,
    );

    // Timings in Spanish
    expect(find.text('Entrada: 09:58'), findsOneWidget);
    expect(find.text('Salida: 11:32'), findsOneWidget);

    // Attendance summary chips in Spanish
    expect(find.text('Total: 18'), findsOneWidget);
    expect(find.text('Presentes: 15'), findsOneWidget);
    expect(find.text('Ausentes: 1'), findsOneWidget);
    expect(find.text('Tarde: 1'), findsOneWidget);
    expect(find.text('Justificados: 1'), findsOneWidget);

    // Ratings in Spanish
    expect(find.text('Comportamiento y Actitud'), findsOneWidget);
    expect(find.text('Satisfactorio'), findsOneWidget);
    expect(find.text('Esfuerzo y Dedicación'), findsOneWidget);
    expect(find.text('Adecuado'), findsOneWidget);

    // Students header & status pill in Spanish
    expect(find.text('Alumnos (1)'), findsOneWidget);
    expect(find.text('Presente'), findsOneWidget);

    // Academic Review section in Spanish
    expect(find.text('REVISIÓN ACADÉMICA'), findsOneWidget);
    expect(find.text('Revisado el 2026-10-26'), findsOneWidget);
  });

  testWidgets('displays all elements correctly in English when English is selected', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen(AppLanguage.english, enStrings));
    await tester.pumpAndSettle();

    // Faculty default fallback in English
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Aula 360 Faculty'),
      ),
      findsOneWidget,
    );

    // Timings in English
    expect(find.text('Entry: 09:58'), findsOneWidget);
    expect(find.text('Exit: 11:32'), findsOneWidget);

    // Attendance summary chips in English
    expect(find.text('Total: 18'), findsOneWidget);
    expect(find.text('Present: 15'), findsOneWidget);
    expect(find.text('Absent: 1'), findsOneWidget);
    expect(find.text('Late: 1'), findsOneWidget);
    expect(find.text('Excused: 1'), findsOneWidget);

    // Ratings in English
    expect(find.text('Conduct & Attitude'), findsOneWidget);
    expect(find.text('Satisfactory'), findsOneWidget);
    expect(find.text('Effort & Dedication'), findsOneWidget);
    expect(find.text('Adequate'), findsOneWidget);

    // Students header & status pill in English
    expect(find.text('Students (1)'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);

    // Academic Review section in English
    expect(find.text('ACADEMIC REVIEW'), findsOneWidget);
    expect(find.text('Reviewed on 2026-10-26'), findsOneWidget);
  });
}

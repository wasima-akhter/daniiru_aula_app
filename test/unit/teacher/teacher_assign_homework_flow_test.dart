import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:aula360/features/teacher_all/classes/data/dtos/class_session_dto.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';
import 'package:aula360/features/teacher_all/homework/domain/repositories/teacher_homework_repository.dart';
import 'package:aula360/features/teacher_all/homework/presentation/providers/teacher_homework_providers.dart';
import 'package:aula360/features/teacher_all/homework/presentation/widgets/assign_homework_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeLanguageNotifier extends LanguageNotifier {
  @override
  Future<LanguageState> build() async {
    return const LanguageState(
      language: AppLanguage.english,
      strings: {},
    );
  }
}

class _MockTeacherHomeworkRepository extends Fake implements TeacherHomeworkRepository {
  CreateHomeworkRequestDto? capturedRequest;

  @override
  Future<TeacherHomeworkDto> createHomework(CreateHomeworkRequestDto payload) async {
    capturedRequest = payload;
    return TeacherHomeworkDto(
      id: '123e4567-e89b-12d3-a456-426614174099',
      cohortId: payload.cohortId,
      subjectId: payload.subjectId,
      sessionId: payload.sessionId,
      teacherId: '123e4567-e89b-12d3-a456-426614174088',
      title: payload.title,
      description: payload.description,
      startDate: payload.startDate,
      dueDate: payload.dueDate,
      subjectName: 'English Literature',
      submissionsCount: 0,
      createdAt: '2026-11-02T10:00:00.000Z',
      updatedAt: '2026-11-02T10:00:00.000Z',
    );
  }

  @override
  Future<PaginatedResult<TeacherHomeworkDto>> getHomework({
    String? cohortId,
    int page = 1,
    int limit = 20,
  }) async {
    return const PaginatedResult<TeacherHomeworkDto>(
      data: [],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('es', null);
  });

  group('ClassSessionDto cohortId and subjectId parsing', () {
    test('parses cohortId and subjectId from top level fields', () {
      final json = {
        'id': 'sess-uuid-1',
        'scheduleId': 'sch-uuid-1',
        'sessionDate': '2026-11-02T09:00:00.000Z',
        'startTime': '09:00',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'subjectName': 'Advanced Mathematics',
        'subjectId': 'sub-uuid-1',
        'cohortId': 'coh-uuid-1',
        'cohortName': 'Grade 10A',
      };

      final dto = ClassSessionDto.fromJson(json);
      expect(dto.cohortId, 'coh-uuid-1');
      expect(dto.subjectId, 'sub-uuid-1');
    });

    test('parses cohortId and subjectId from nested cohort and subject objects', () {
      final json = {
        'id': 'sess-uuid-2',
        'scheduleId': 'sch-uuid-2',
        'sessionDate': '2026-11-02T09:00:00.000Z',
        'startTime': '09:00',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'subject': {
          'id': 'sub-nested-uuid',
          'name': 'Physics 101',
        },
        'cohort': {
          'id': 'coh-nested-uuid',
          'name': 'Cohort B',
        },
      };

      final dto = ClassSessionDto.fromJson(json);
      expect(dto.cohortId, 'coh-nested-uuid');
      expect(dto.subjectId, 'sub-nested-uuid');
      expect(dto.subjectName, 'Physics 101');
      expect(dto.cohortName, 'Cohort B');
    });

    test('parses cohortId and subjectId from nested schedule object', () {
      final json = {
        'id': 'sess-uuid-3',
        'scheduleId': 'sch-uuid-3',
        'sessionDate': '2026-11-02T09:00:00.000Z',
        'startTime': '09:00',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'subjectName': 'Chemistry',
        'schedule': {
          'cohortId': 'coh-sch-uuid',
          'subjectId': 'sub-sch-uuid',
          'cohortName': 'Chemistry Lab Group',
        },
      };

      final dto = ClassSessionDto.fromJson(json);
      expect(dto.cohortId, 'coh-sch-uuid');
      expect(dto.subjectId, 'sub-sch-uuid');
    });

    test('falls back to scheduleId when subjectId is not provided (Swagger behavior)', () {
      final json = {
        'id': 'sess-uuid-4',
        'scheduleId': 'sch-uuid-4-fallback',
        'sessionDate': '2026-11-02T09:00:00.000Z',
        'startTime': '09:00',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'subjectName': 'Biology',
        'cohortId': 'coh-uuid-4',
        'cohortName': 'Bio Cohort',
      };

      final dto = ClassSessionDto.fromJson(json);
      expect(dto.cohortId, 'coh-uuid-4');
      // subjectId falls back to scheduleId
      expect(dto.subjectId, 'sch-uuid-4-fallback');
    });

    test('extracts cohortId and subjectId from nested homework array if present', () {
      final json = {
        'id': 'sess-uuid-5',
        'scheduleId': 'sch-uuid-5',
        'sessionDate': '2026-11-02T09:00:00.000Z',
        'startTime': '09:00',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'subjectName': 'English Literature',
        'homework': [
          {
            'id': 'hw-uuid-1',
            'cohortId': 'coh-from-hw-uuid',
            'subjectId': 'sub-from-hw-uuid',
          }
        ],
      };

      final dto = ClassSessionDto.fromJson(json);
      expect(dto.cohortId, 'coh-from-hw-uuid');
      expect(dto.subjectId, 'sub-from-hw-uuid');
    });
  });

  group('AssignHomeworkBottomSheet Widget & API flow', () {
    testWidgets('displays cohort and subject badges and passes actual UUIDs on submission', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepository = _MockTeacherHomeworkRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith(_FakeLanguageNotifier.new),
            teacherHomeworkRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (ctx, ref, _) => ElevatedButton(
                    onPressed: () {
                      showAssignHomeworkBottomSheet(
                        context: ctx,
                        ref: ref,
                        sessionId: '2a6e335a-bcb2-44f9-818d-3a0371500300',
                        cohortId: '123e4567-e89b-12d3-a456-426614174002',
                        cohortName: 'Group 1',
                        subjectId: '123e4567-e89b-12d3-a456-426614174001',
                        subjectName: 'English Literature',
                        initialTitle: 'Reading Exercise',
                        initialDescription: 'Read pages 45 to 60',
                      );
                    },
                    child: const Text('Open Bottomsheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to open bottom sheet
      await tester.tap(find.text('Open Bottomsheet'));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Create New Homework'), findsOneWidget);

      // Check chips showing human names
      expect(find.text('Group 1'), findsWidgets);
      expect(find.text('English Literature'), findsWidgets);

      // Check active status badge
      expect(find.text('Active'), findsOneWidget);

      // Scroll bottom sheet to ensure submit button is visible
      await tester.drag(find.text('Create New Homework'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap Publish Homework button
      final publishButton = find.text('Publish Homework');
      expect(publishButton, findsOneWidget);
      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      // Verify the request passed to API had the real UUIDs, not human names!
      expect(mockRepository.capturedRequest, isNotNull);
      final req = mockRepository.capturedRequest!;
      expect(req.cohortId, '123e4567-e89b-12d3-a456-426614174002');
      expect(req.subjectId, '123e4567-e89b-12d3-a456-426614174001');
      expect(req.sessionId, '2a6e335a-bcb2-44f9-818d-3a0371500300');
      expect(req.title, 'Reading Exercise');
      expect(req.description, 'Read pages 45 to 60');
      expect(req.dueDate, isNotEmpty);
    });
  });
}

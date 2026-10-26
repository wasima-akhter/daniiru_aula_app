import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/parent_all/data/dtos/child_schedule_dto.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/domain/models/parent_models.dart';
import 'package:aula360/features/parent_all/domain/repositories/parent_repository.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_schedule_controller.dart';
import 'package:aula360/features/parent_all/schedule/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeDateScheduleParentRepository extends Fake implements ParentRepository {
  final List<ChildModel> mockChildren;
  DateTime? lastFromDate;
  DateTime? lastToDate;
  String? lastChildId;

  _FakeDateScheduleParentRepository({required this.mockChildren});

  @override
  Future<List<ChildModel>> getChildren() async => mockChildren;

  @override
  Future<List<ChildScheduleSessionDto>> getChildSchedule(
    String childId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    lastChildId = childId;
    lastFromDate = fromDate;
    lastToDate = toDate;

    // Return a session on 2027-04-15
    return [
      ChildScheduleSessionDto(
        id: 'session-future-1',
        scheduleId: 'sch-future-1',
        subjectName: 'Physics 2027',
        cohortName: 'Advanced Grade',
        teacherName: 'Prof. Einstein',
        classroomRoomNumber: 'Lab Alpha',
        startTime: '10:00',
        endTime: '11:30',
        sessionDate: DateTime(2027, 4, 15, 10, 0),
        status: 'SCHEDULED',
      ),
    ];
  }
}

class _FakeLanguageNotifier extends LanguageNotifier {
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

  final testChild = const ChildModel(
    id: 'child-abc',
    name: 'Emily Watson',
    grade: '5th Grade',
    room: 'Aula 5B',
    imageUrl: '',
    parentTeacher: 'Prof. Einstein',
    attendance: 100,
    present: 15,
    absent: 0,
    late: 0,
  );

  testWidgets(
    'ScheduleScreen filters for any day of any month of any year and supports quick jump back to today',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDateScheduleParentRepository(mockChildren: [testChild]);

      late WidgetRef savedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parentRepositoryProvider.overrideWithValue(repo),
            languageProvider.overrideWith(_FakeLanguageNotifier.new),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, child) => Consumer(
              builder: (context, ref, _) {
                savedRef = ref;
                return const MaterialApp(
                  home: ScheduleScreen(),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify filter button exists
      expect(find.text('Filter Date'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);

      // Verify currently today is selected
      expect(find.text('Today'), findsOneWidget);

      // Now filter for any day of any month of any year: e.g. 15 April 2027!
      final targetFutureDate = DateTime(2027, 4, 15);
      savedRef
          .read(parentScheduleControllerProvider.notifier)
          .selectCustomDate(targetFutureDate);

      await tester.pumpAndSettle();

      // Verify the API was queried with fromDate & toDate for that custom month
      expect(repo.lastChildId, 'child-abc');
      expect(repo.lastFromDate, DateTime.utc(2027, 4, 1));
      expect(repo.lastToDate, DateTime.utc(2027, 4 + 1, 0, 23, 59, 59));

      // Verify the title displays the formatted date with the year 2027
      expect(find.textContaining('15 Apr 2027'), findsOneWidget);

      // Verify the session for 2027-04-15 is displayed
      expect(find.text('Physics 2027'), findsOneWidget);

      // Verify a "Today" quick jump button is shown when not on today
      expect(find.byIcon(Icons.today_rounded), findsOneWidget);

      // Tap on "Today" button to return to today
      await tester.tap(find.byIcon(Icons.today_rounded));
      await tester.pumpAndSettle();

      // Verify anchor and selection returned to today
      final state = savedRef.read(parentScheduleControllerProvider);
      final now = DateTime.now();
      expect(state.selectedDate.day, now.day);
      expect(state.selectedDate.month, now.month);
      expect(state.selectedDate.year, now.year);
    },
  );
}

import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/parent_all/data/dtos/child_schedule_dto.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/domain/models/parent_models.dart';
import 'package:aula360/features/parent_all/domain/repositories/parent_repository.dart';
import 'package:aula360/features/parent_all/schedule/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeScheduleParentRepository extends Fake implements ParentRepository {
  final List<ChildModel> mockChildren;
  final Map<String, List<ChildScheduleSessionDto>> childSchedules;
  final List<String> scheduleCalls = [];

  FakeScheduleParentRepository({
    required this.mockChildren,
    required this.childSchedules,
  });

  @override
  Future<List<ChildModel>> getChildren() async => mockChildren;

  @override
  Future<List<ChildScheduleSessionDto>> getChildSchedule(
    String childId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    scheduleCalls.add(childId);
    return childSchedules[childId] ?? const [];
  }
}

class FakeScheduleLanguageNotifier extends LanguageNotifier {
  @override
  Future<LanguageState> build() async {
    return const LanguageState(
      language: AppLanguage.spanish,
      strings: {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('en', null);
  });

  final mockChildren = [
    const ChildModel(
      id: 'child-1',
      name: 'Lucas Rodriguez',
      grade: '4th Grade',
      room: 'Aula 4A',
      imageUrl: '',
      parentTeacher: 'Prof. Gauss',
      attendance: 100,
      present: 10,
      absent: 0,
      late: 0,
    ),
    const ChildModel(
      id: 'child-2',
      name: 'Sofia Rodriguez',
      grade: '2nd Grade',
      room: 'Aula 2B',
      imageUrl: '',
      parentTeacher: 'Prof. Curie',
      attendance: 98,
      present: 9,
      absent: 0,
      late: 1,
    ),
    const ChildModel(
      id: 'child-3',
      name: 'Mateo Rodriguez',
      grade: 'Kindergarten',
      room: 'Aula 0A',
      imageUrl: '',
      parentTeacher: 'Prof. Picasso',
      attendance: 95,
      present: 8,
      absent: 1,
      late: 0,
    ),
  ];

  final mockSchedules = <String, List<ChildScheduleSessionDto>>{
    'child-1': [
      ChildScheduleSessionDto(
        id: 'session-lucas-1',
        scheduleId: 'sch-1',
        subjectName: 'Matemáticas Lucas',
        cohortName: '4th Grade',
        teacherName: 'Prof. Gauss',
        classroomRoomNumber: 'Aula 4A',
        startTime: '09:00',
        endTime: '10:00',
        sessionDate: DateTime.now(),
        status: 'SCHEDULED',
      ),
    ],
    'child-2': [
      ChildScheduleSessionDto(
        id: 'session-sofia-1',
        scheduleId: 'sch-2',
        subjectName: 'Ciencias Sofia',
        cohortName: '2nd Grade',
        teacherName: 'Prof. Curie',
        classroomRoomNumber: 'Lab 2',
        startTime: '10:30',
        endTime: '11:30',
        sessionDate: DateTime.now(),
        status: 'SCHEDULED',
      ),
    ],
    'child-3': [
      ChildScheduleSessionDto(
        id: 'session-mateo-1',
        scheduleId: 'sch-3',
        subjectName: 'Arte Mateo',
        cohortName: 'Kindergarten',
        teacherName: 'Prof. Picasso',
        classroomRoomNumber: 'Taller 1',
        startTime: '12:00',
        endTime: '13:00',
        sessionDate: DateTime.now(),
        status: 'SCHEDULED',
      ),
    ],
  };

  Widget buildTestScreen(FakeScheduleParentRepository repository) {
    return ProviderScope(
      overrides: [
        parentRepositoryProvider.overrideWithValue(repository),
        languageProvider.overrideWith(FakeScheduleLanguageNotifier.new),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => const MaterialApp(
          home: ScheduleScreen(),
        ),
      ),
    );
  }

  testWidgets(
    'ScheduleScreen shows all children in horizontal scroll and hits API when child is selected',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeScheduleParentRepository(
        mockChildren: mockChildren,
        childSchedules: mockSchedules,
      );

      await tester.pumpWidget(buildTestScreen(repo));
      await tester.pumpAndSettle();

      // Verify that children are rendered
      expect(find.text('Lucas Rodriguez'), findsOneWidget);
      expect(find.text('Sofia Rodriguez'), findsOneWidget);

      // Verify initial API call was made for child-1 (Lucas)
      expect(repo.scheduleCalls.contains('child-1'), isTrue);
      expect(find.text('Matemáticas Lucas'), findsOneWidget);

      // Scroll horizontally to reveal the 3rd child (Mateo Rodriguez)
      await tester.drag(find.text('Sofia Rodriguez'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // All 3 children can be displayed and accessed via horizontal scroll
      expect(find.text('Mateo Rodriguez'), findsOneWidget);

      // Tap on Sofia Rodriguez to select her and hit the API for her schedule
      final sofiaCard = find.text('Sofia Rodriguez');
      await tester.ensureVisible(sofiaCard);
      await tester.tap(sofiaCard);
      await tester.pumpAndSettle();

      // Verify API was called with child-2 (Sofia)
      expect(repo.scheduleCalls.contains('child-2'), isTrue);

      // Verify Sofia's class session is now displayed
      expect(find.text('Ciencias Sofia'), findsOneWidget);
    },
  );

  testWidgets(
    'ScheduleScreen displays single child full-width when only one child is linked',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeScheduleParentRepository(
        mockChildren: [mockChildren[0]],
        childSchedules: mockSchedules,
      );

      await tester.pumpWidget(buildTestScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Lucas Rodriguez'), findsOneWidget);
      expect(find.text('Sofia Rodriguez'), findsNothing);
      expect(repo.scheduleCalls.contains('child-1'), isTrue);
      expect(find.text('Matemáticas Lucas'), findsOneWidget);
    },
  );
}

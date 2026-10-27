import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aula360/features/teacher_all/classes/data/dtos/class_session_dto.dart';
import 'package:aula360/features/teacher_all/classes/domain/repositories/teacher_classes_repository.dart';
import 'package:aula360/features/teacher_all/classes/presentation/providers/teacher_classes_providers.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/home/presentation/controllers/teacher_home_controller.dart';
import 'package:aula360/utils/app_strings/app_strings.dart';

class _FakeTeacherClassesRepository implements TeacherClassesRepository {
  List<ClassSessionDto> sessions = [];

  @override
  Future<List<ClassSessionDto>> getSessions({DateTime? date}) async {
    return sessions;
  }

  @override
  Future<ClassSessionDto> getSessionDetail(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<ClassSessionDto> startSession(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AcademyClass>> getTodayClasses() async {
    return [];
  }

  @override
  Future<List<AcademyClass>> getUpcomingClasses() async {
    return [];
  }
}

void main() {
  group('Teacher Home Controller & Next Session Tests', () {
    test('parseTimeToMinutes correctly parses various time formats', () {
      expect(parseTimeToMinutes('08:00'), 480);
      expect(parseTimeToMinutes('09:30'), 570);
      expect(parseTimeToMinutes('13:45'), 825);
      expect(parseTimeToMinutes('01:30 PM'), 810);
      expect(parseTimeToMinutes('2026-10-27T10:15:00.000Z'), 615);
      expect(parseTimeToMinutes(''), 0);
      expect(parseTimeToMinutes('invalid'), 0);
    });

    test('TeacherHomeState.nextSession prioritizes ONGOING session', () {
      const state = TeacherHomeState(
        schedule: [
          HomeScheduleItem(
            id: '1',
            startTime: '08:00',
            endTime: '09:30',
            title: 'Math Morning',
            subtitle: 'Group A',
            room: '101',
            group: 'Group A',
            students: 24,
            type: HomeClassType.scheduled,
            rawStatus: 'COMPLETED',
          ),
          HomeScheduleItem(
            id: '2',
            startTime: '10:00',
            endTime: '11:30',
            title: 'Active Math',
            subtitle: 'Group B',
            room: '102',
            group: 'Group B',
            students: 24,
            type: HomeClassType.next,
            rawStatus: 'ONGOING',
          ),
          HomeScheduleItem(
            id: '3',
            startTime: '12:00',
            endTime: '13:30',
            title: 'Afternoon Math',
            subtitle: 'Group C',
            room: '103',
            group: 'Group C',
            students: 24,
            type: HomeClassType.scheduled,
            rawStatus: 'SCHEDULED',
          ),
        ],
      );

      final next = state.nextSession;
      expect(next, isNotNull);
      expect(next!.id, '2');
      expect(next.rawStatus, 'ONGOING');
      expect(next.title, 'Active Math');
    });

    test('TeacherHomeState.nextSession returns next SCHEDULED session if no ONGOING', () {
      const state = TeacherHomeState(
        schedule: [
          HomeScheduleItem(
            id: '1',
            startTime: '08:00',
            endTime: '09:30',
            title: 'First Period',
            subtitle: 'Group A',
            room: '101',
            group: 'Group A',
            students: 24,
            type: HomeClassType.scheduled,
            rawStatus: 'COMPLETED',
          ),
          HomeScheduleItem(
            id: '2',
            startTime: '10:00',
            endTime: '11:30',
            title: 'Second Period',
            subtitle: 'Group B',
            room: '102',
            group: 'Group B',
            students: 24,
            type: HomeClassType.scheduled,
            rawStatus: 'CANCELLED',
          ),
          HomeScheduleItem(
            id: '3',
            startTime: '23:00',
            endTime: '23:59',
            title: 'Late Night Review',
            subtitle: 'Group C',
            room: '103',
            group: 'Group C',
            students: 24,
            type: HomeClassType.scheduled,
            rawStatus: 'SCHEDULED',
          ),
        ],
      );

      final next = state.nextSession;
      expect(next, isNotNull);
      expect(next!.id, '3');
      expect(next.rawStatus, 'SCHEDULED');
      expect(next.title, 'Late Night Review');
    });

    test('TeacherHomeState.nextSession returns null when all sessions are COMPLETED or CANCELLED', () {
      const state = TeacherHomeState(
        schedule: [
          HomeScheduleItem(
            id: '1',
            startTime: '08:00',
            endTime: '09:30',
            title: 'First Period',
            subtitle: 'Group A',
            room: '101',
            group: 'Group A',
            students: 24,
            type: HomeClassType.scheduled,
            rawStatus: 'COMPLETED',
          ),
          HomeScheduleItem(
            id: '2',
            startTime: '10:00',
            endTime: '11:30',
            title: 'Second Period',
            subtitle: 'Group B',
            room: '102',
            group: 'Group B',
            students: 24,
            type: HomeClassType.scheduled,
            rawStatus: 'CANCELLED',
          ),
        ],
      );

      expect(state.nextSession, isNull);
    });

    test('TeacherHomeState.nextSession returns null when schedule is empty', () {
      const state = TeacherHomeState(schedule: []);
      expect(state.nextSession, isNull);
    });

    test('Translation keys for session status exist in en.json and es.json', () {
      final enFile = File('assets/lang/en.json');
      final esFile = File('assets/lang/es.json');

      expect(enFile.existsSync(), isTrue);
      expect(esFile.existsSync(), isTrue);

      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final esMap = jsonDecode(esFile.readAsStringSync()) as Map<String, dynamic>;

      final expectedKeys = [
        AppStrings.statusOngoing,
        AppStrings.statusScheduled,
        AppStrings.statusCompleted,
        AppStrings.statusCancelled,
      ];

      for (final key in expectedKeys) {
        expect(enMap.containsKey(key), isTrue, reason: 'Missing $key in en.json');
        expect(esMap.containsKey(key), isTrue, reason: 'Missing $key in es.json');
        expect(enMap[key].toString().isNotEmpty, isTrue);
        expect(esMap[key].toString().isNotEmpty, isTrue);
      }

      expect(enMap[AppStrings.statusOngoing], 'Ongoing');
      expect(esMap[AppStrings.statusOngoing], 'En curso');
      expect(enMap[AppStrings.statusScheduled], 'Scheduled');
      expect(esMap[AppStrings.statusScheduled], 'Programada');
      expect(enMap[AppStrings.statusCompleted], 'Completed');
      expect(esMap[AppStrings.statusCompleted], 'Completada');
      expect(enMap[AppStrings.statusCancelled], 'Cancelled');
      expect(esMap[AppStrings.statusCancelled], 'Cancelada');
    });

    test('TeacherHomeController.loadHomeData sorts sessions chronologically', () async {
      final fakeRepo = _FakeTeacherClassesRepository()
        ..sessions = [
          const ClassSessionDto(
            id: 'session-3',
            scheduleId: 'sched-3',
            sessionDate: '2026-10-27',
            startTime: '14:00',
            endTime: '15:30',
            status: 'SCHEDULED',
            subjectName: 'Late Afternoon Math',
            cohortName: 'Cohort C',
            teacherName: 'Dr. Jenkins',
            classroomRoomNumber: '301',
          ),
          const ClassSessionDto(
            id: 'session-1',
            scheduleId: 'sched-1',
            sessionDate: '2026-10-27',
            startTime: '08:30',
            endTime: '10:00',
            status: 'COMPLETED',
            subjectName: 'Early Morning Physics',
            cohortName: 'Cohort A',
            teacherName: 'Dr. Jenkins',
            classroomRoomNumber: '101',
          ),
          const ClassSessionDto(
            id: 'session-2',
            scheduleId: 'sched-2',
            sessionDate: '2026-10-27',
            startTime: '10:30',
            endTime: '12:00',
            status: 'ONGOING',
            subjectName: 'Midday Chemistry',
            cohortName: 'Cohort B',
            teacherName: 'Dr. Jenkins',
            classroomRoomNumber: '201',
          ),
        ];

      final container = ProviderContainer(
        overrides: [
          teacherClassesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(teacherHomeControllerProvider.notifier);
      await notifier.loadHomeData();

      final state = container.read(teacherHomeControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.schedule.length, 3);

      // Verify sorted order: 08:30, 10:30, 14:00
      expect(state.schedule[0].startTime, '08:30');
      expect(state.schedule[0].id, 'session-1');
      expect(state.schedule[0].rawStatus, 'COMPLETED');

      expect(state.schedule[1].startTime, '10:30');
      expect(state.schedule[1].id, 'session-2');
      expect(state.schedule[1].rawStatus, 'ONGOING');

      expect(state.schedule[2].startTime, '14:00');
      expect(state.schedule[2].id, 'session-3');
      expect(state.schedule[2].rawStatus, 'SCHEDULED');

      // Verify nextSession resolves to the ONGOING session
      expect(state.nextSession, isNotNull);
      expect(state.nextSession!.id, 'session-2');
      expect(state.nextSession!.rawStatus, 'ONGOING');
    });
  });
}

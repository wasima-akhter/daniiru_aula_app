import 'package:flutter_test/flutter_test.dart';

import 'package:aula360/core/router/route_path.dart';
import 'package:aula360/features/teacher_all/attendance/teacher_report_submit_confirm_screen.dart';
import 'package:aula360/features/teacher_all/classes/data/dtos/class_session_dto.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';
import 'package:aula360/features/teacher_all/homework/teacher_homework_screen.dart';

void main() {
  group('Report Submission to Homework Flow Tests', () {
    test('ClassSessionDto parses cohortId and subjectId from session details', () {
      final json = {
        'id': '2a6e335a-bcb2-44f9-818d-3a0371500300',
        'scheduleId': '123e4567-e89b-12d3-a456-426614174001',
        'sessionDate': '2026-11-02T00:00:00.000Z',
        'startTime': '09:00',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'subjectName': 'English Literature',
        'subjectId': '777e4567-e89b-12d3-a456-426614174777',
        'cohortId': '888e4567-e89b-12d3-a456-426614174888',
        'cohortName': 'Group 1',
        'teacherName': 'Dr. Smith',
        'classroomRoomNumber': '101',
      };

      final dto = ClassSessionDto.fromJson(json);
      expect(dto.id, '2a6e335a-bcb2-44f9-818d-3a0371500300');
      expect(dto.cohortId, '888e4567-e89b-12d3-a456-426614174888');
      expect(dto.subjectId, '777e4567-e89b-12d3-a456-426614174777');
      expect(dto.cohortName, 'Group 1');
      expect(dto.subjectName, 'English Literature');

      // Test mapping to AcademyClass
      final academyClass = dto.toAcademyClass();
      expect(academyClass.id, '2a6e335a-bcb2-44f9-818d-3a0371500300');
      expect(academyClass.cohortId, '888e4567-e89b-12d3-a456-426614174888');
      expect(academyClass.subjectId, '777e4567-e89b-12d3-a456-426614174777');
      expect(academyClass.group, 'Group 1');
      expect(academyClass.title, 'English Literature');
    });

    test('ClassSessionDto fallbacks to nested schedule and homework IDs', () {
      final json = {
        'id': 'session-uuid',
        'scheduleId': 'sched-uuid',
        'sessionDate': '2026-11-02T00:00:00.000Z',
        'startTime': '09:00',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'subjectName': 'Mathematics',
        'cohortName': 'Grade 10',
        'teacherName': 'Prof. Doe',
        'classroomRoomNumber': '201',
        'schedule': {
          'cohortId': 'cohort-from-schedule-uuid',
          'subjectId': 'subject-from-schedule-uuid',
        },
      };

      final dto = ClassSessionDto.fromJson(json);
      expect(dto.cohortId, 'cohort-from-schedule-uuid');
      expect(dto.subjectId, 'subject-from-schedule-uuid');
    });

    test('TeacherReportSubmittedScreen correctly stores constructor arguments', () {
      const activeClass = AcademyClass(
        id: 'session-123',
        scheduleId: 'sched-123',
        time: '10:00 - 11:30',
        title: 'Advanced Mathematics',
        subtitle: 'Bachillerato 1',
        room: 'Room 204',
        group: 'Group 1',
        students: 25,
        status: ClassStatus.scheduled,
        cohortId: '888e4567-e89b-12d3-a456-426614174888',
        subjectId: '777e4567-e89b-12d3-a456-426614174777',
      );

      const screen = TeacherReportSubmittedScreen(
        sessionId: 'session-123',
        homeworkText: 'Read chapters 4 and 5',
        initialClass: activeClass,
      );

      expect(screen.sessionId, 'session-123');
      expect(screen.homeworkText, 'Read chapters 4 and 5');
      expect(screen.initialClass, activeClass);
      expect(screen.initialClass?.cohortId, '888e4567-e89b-12d3-a456-426614174888');
      expect(screen.initialClass?.subjectId, '777e4567-e89b-12d3-a456-426614174777');
    });

    test('TeacherHomeworkScreen accepts resolved UUIDs and human names', () {
      const homeworkScreen = TeacherHomeworkScreen(
        initialCohortId: '888e4567-e89b-12d3-a456-426614174888',
        initialCohortName: 'Group 1',
        initialSubjectId: '777e4567-e89b-12d3-a456-426614174777',
        initialSubjectName: 'English Literature',
        sessionId: '2a6e335a-bcb2-44f9-818d-3a0371500300',
        initialTitle: 'English Literature - Homework',
        initialDescription: 'Complete exercises',
        autoOpenCreateSheet: true,
        fromClassFlow: true,
      );

      expect(homeworkScreen.initialCohortId, '888e4567-e89b-12d3-a456-426614174888');
      expect(homeworkScreen.initialCohortName, 'Group 1');
      expect(homeworkScreen.initialSubjectId, '777e4567-e89b-12d3-a456-426614174777');
      expect(homeworkScreen.initialSubjectName, 'English Literature');
      expect(homeworkScreen.sessionId, '2a6e335a-bcb2-44f9-818d-3a0371500300');
      expect(homeworkScreen.initialTitle, 'English Literature - Homework');
      expect(homeworkScreen.initialDescription, 'Complete exercises');
      expect(homeworkScreen.autoOpenCreateSheet, isTrue);
      expect(homeworkScreen.fromClassFlow, isTrue);
    });

    test('TeacherHomeworkScreen.isValidUuid correctly validates UUID format', () {
      expect(TeacherHomeworkScreen.isValidUuid('2a6e335a-bcb2-44f9-818d-3a0371500300'), isTrue);
      expect(TeacherHomeworkScreen.isValidUuid('777E4567-E89B-12D3-A456-426614174777'), isTrue);
      expect(TeacherHomeworkScreen.isValidUuid('Group 1'), isFalse);
      expect(TeacherHomeworkScreen.isValidUuid('English Littrature'), isFalse);
      expect(TeacherHomeworkScreen.isValidUuid(''), isFalse);
      expect(TeacherHomeworkScreen.isValidUuid(null), isFalse);
    });

    test('CreateHomeworkRequestDto always emits valid UTC ISO datetimes with Z', () {
      final localStart = DateTime(2026, 10, 26, 9, 8, 55);
      final localDue = DateTime(2026, 11, 2, 9, 8, 36);

      final dto = CreateHomeworkRequestDto(
        cohortId: '888e4567-e89b-12d3-a456-426614174888',
        subjectId: '777e4567-e89b-12d3-a456-426614174777',
        sessionId: '2a6e335a-bcb2-44f9-818d-3a0371500300',
        title: 'Problem Set 4',
        description: 'Solve exercises 1 through 10',
        startDate: localStart.toIso8601String(), // Even if unformatted local string passed
        dueDate: localDue.toIso8601String(),
      );

      final json = dto.toJson();
      expect(json['cohortId'], '888e4567-e89b-12d3-a456-426614174888');
      expect(json['subjectId'], '777e4567-e89b-12d3-a456-426614174777');
      expect(json['sessionId'], '2a6e335a-bcb2-44f9-818d-3a0371500300');
      expect(json['title'], 'Problem Set 4');
      expect(json['description'], 'Solve exercises 1 through 10');

      // Validating ISO datetimes end in 'Z' (UTC format)
      expect(json['startDate'], localStart.toUtc().toIso8601String());
      expect((json['startDate'] as String).endsWith('Z'), isTrue);
      expect(json['dueDate'], localDue.toUtc().toIso8601String());
      expect((json['dueDate'] as String).endsWith('Z'), isTrue);
    });

    test('RoutePath contains teacherReportSubmitted and teacherHomework paths', () {
      expect(RoutePath.teacherReportSubmitted, 'teacherReportSubmitted');
      expect(RoutePath.teacherHomework, 'teacherHomework');
    });
  });
}

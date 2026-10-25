import 'package:flutter_test/flutter_test.dart';

import 'package:aula360/core/router/route_path.dart';
import 'package:aula360/features/teacher_all/attendance/teacher_report_submit_confirm_screen.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';
import 'package:aula360/features/teacher_all/homework/teacher_homework_screen.dart';

void main() {
  group('Report Submission to Homework Flow Tests', () {
    test('TeacherReportSubmittedScreen correctly stores constructor arguments', () {
      const activeClass = AcademyClass(
        id: 'session-123',
        scheduleId: 'sched-123',
        time: '10:00 - 11:30',
        title: 'Advanced Mathematics',
        subtitle: 'Bachillerato 1',
        room: 'Room 204',
        group: 'Cohort 10-A',
        students: 25,
        status: ClassStatus.scheduled,
      );

      const screen = TeacherReportSubmittedScreen(
        sessionId: 'session-123',
        homeworkText: 'Read chapters 4 and 5',
        initialClass: activeClass,
      );

      expect(screen.sessionId, 'session-123');
      expect(screen.homeworkText, 'Read chapters 4 and 5');
      expect(screen.initialClass, activeClass);
    });

    test('TeacherHomeworkScreen accepts class-flow arguments and auto-open flag', () {
      const homeworkScreen = TeacherHomeworkScreen(
        initialCohortId: 'Cohort 10-A',
        initialSubjectId: 'Advanced Mathematics',
        sessionId: 'session-123',
        initialTitle: 'Advanced Mathematics - Homework',
        initialDescription: 'Read chapters 4 and 5',
        autoOpenCreateSheet: true,
        fromClassFlow: true,
      );

      expect(homeworkScreen.initialCohortId, 'Cohort 10-A');
      expect(homeworkScreen.initialSubjectId, 'Advanced Mathematics');
      expect(homeworkScreen.sessionId, 'session-123');
      expect(homeworkScreen.initialTitle, 'Advanced Mathematics - Homework');
      expect(homeworkScreen.initialDescription, 'Read chapters 4 and 5');
      expect(homeworkScreen.autoOpenCreateSheet, isTrue);
      expect(homeworkScreen.fromClassFlow, isTrue);
    });

    test('CreateHomeworkRequestDto correctly serializes sessionId from session flow', () {
      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 7));

      final dto = CreateHomeworkRequestDto(
        cohortId: 'Cohort 10-A',
        subjectId: 'Advanced Mathematics',
        sessionId: 'session-123',
        title: 'Problem Set 4',
        description: 'Solve exercises 1 through 10',
        startDate: now.toIso8601String(),
        dueDate: dueDate.toIso8601String(),
      );

      final json = dto.toJson();
      expect(json['cohortId'], 'Cohort 10-A');
      expect(json['subjectId'], 'Advanced Mathematics');
      expect(json['sessionId'], 'session-123');
      expect(json['title'], 'Problem Set 4');
      expect(json['description'], 'Solve exercises 1 through 10');
      expect(json['startDate'], now.toIso8601String());
      expect(json['dueDate'], dueDate.toIso8601String());
    });

    test('RoutePath contains teacherReportSubmitted and teacherHomework paths', () {
      expect(RoutePath.teacherReportSubmitted, 'teacherReportSubmitted');
      expect(RoutePath.teacherHomework, 'teacherHomework');
    });
  });
}

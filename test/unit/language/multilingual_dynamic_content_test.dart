import 'package:aula360/features/legal/data/dtos/legal_content_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/announcement_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/child_homework_dto.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multilingual Dynamic Content DTOs', () {
    test('AnnouncementDto correctly parses translation metadata', () {
      final json = {
        'id': 'e4b2d5a8-3f1c-4b9e-9d2a-1a2b3c4d5e6f',
        'title': 'Important School Meeting',
        'body': 'Classes will start at 9:00 AM tomorrow due to teacher development.',
        'audience': 'ALL',
        'sourceLocale': 'es',
        'displayedLocale': 'en',
        'isTranslated': true,
        'translationStatus': 'READY',
        'publishedAt': '2026-10-25T08:00:00.000Z',
      };

      final dto = AnnouncementDto.fromJson(json);

      expect(dto.id, equals('e4b2d5a8-3f1c-4b9e-9d2a-1a2b3c4d5e6f'));
      expect(dto.title, equals('Important School Meeting'));
      expect(dto.sourceLocale, equals('es'));
      expect(dto.displayedLocale, equals('en'));
      expect(dto.isTranslated, isTrue);
      expect(dto.translationStatus, equals('READY'));

      final serialized = dto.toJson();
      expect(serialized['sourceLocale'], equals('es'));
      expect(serialized['displayedLocale'], equals('en'));
      expect(serialized['isTranslated'], isTrue);
      expect(serialized['translationStatus'], equals('READY'));
    });

    test('AnnouncementDto uses safe fallbacks when translation metadata is absent', () {
      final json = {
        'id': '123',
        'title': 'Sample Announcement',
        'body': 'Content body',
        'audience': 'PARENTS',
      };

      final dto = AnnouncementDto.fromJson(json);

      expect(dto.sourceLocale, equals('en'));
      expect(dto.displayedLocale, equals('en'));
      expect(dto.isTranslated, isFalse);
      expect(dto.translationStatus, equals('READY'));
    });

    test('ChildHomeworkDto propagates translation metadata to HomeworkModel', () {
      final json = {
        'id': 'hw-001',
        'title': 'Math Exercise 4',
        'description': 'Complete chapter 4 questions',
        'subjectName': 'Mathematics',
        'dueDate': '2026-11-15T18:00:00.000Z',
        'status': 'PENDING',
        'sourceLocale': 'es',
        'displayedLocale': 'en',
        'isTranslated': true,
        'translationStatus': 'PENDING',
      };

      final dto = ChildHomeworkDto.fromJson(json);
      final model = dto.toModel();

      expect(model.id, equals('hw-001'));
      expect(model.title, equals('Math Exercise 4'));
      expect(model.sourceLocale, equals('es'));
      expect(model.displayedLocale, equals('en'));
      expect(model.isTranslated, isTrue);
      expect(model.translationStatus, equals('PENDING'));
    });

    test('TeacherHomeworkDto correctly serializes and deserializes translation fields', () {
      final json = {
        'id': 'thw-001',
        'cohortId': 'c1',
        'subjectId': 's1',
        'teacherId': 't1',
        'title': 'Physics Lab Report',
        'description': 'Submit measurements',
        'startDate': '2026-11-01T00:00:00.000Z',
        'dueDate': '2026-11-08T00:00:00.000Z',
        'subjectName': 'Physics',
        'submissionsCount': 12,
        'createdAt': '2026-11-01T00:00:00.000Z',
        'updatedAt': '2026-11-01T00:00:00.000Z',
        'sourceLocale': 'en',
        'displayedLocale': 'es',
        'isTranslated': true,
        'translationStatus': 'READY',
      };

      final dto = TeacherHomeworkDto.fromJson(json);

      expect(dto.title, equals('Physics Lab Report'));
      expect(dto.sourceLocale, equals('en'));
      expect(dto.displayedLocale, equals('es'));
      expect(dto.isTranslated, isTrue);
      expect(dto.translationStatus, equals('READY'));

      final map = dto.toJson();
      expect(map['isTranslated'], isTrue);
      expect(map['translationStatus'], equals('READY'));
    });

    test('LegalContentDto maps translation fields to LegalContent entity', () {
      final json = {
        'legalContentType': 'TERMS_AND_CONDITION',
        'content': '<p>Terms content</p>',
        'sourceLocale': 'es',
        'displayedLocale': 'en',
        'isTranslated': true,
        'translationStatus': 'READY',
      };

      final dto = LegalContentDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.sourceLocale, equals('es'));
      expect(entity.displayedLocale, equals('en'));
      expect(entity.isTranslated, isTrue);
      expect(entity.translationStatus, equals('READY'));
    });
  });
}


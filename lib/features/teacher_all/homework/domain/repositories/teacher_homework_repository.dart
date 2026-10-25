import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';

abstract class TeacherHomeworkRepository {
  Future<TeacherHomeworkDto> createHomework(CreateHomeworkRequestDto payload);
  Future<PaginatedResult<TeacherHomeworkDto>> getHomework({
    String? cohortId,
    int page = 1,
    int limit = 20,
  });
  Future<HomeworkSubmissionDto> markHomeworkSubmission(
    String homeworkId,
    String studentId,
    MarkHomeworkSubmissionRequestDto payload,
  );
}

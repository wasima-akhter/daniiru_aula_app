import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:aula360/features/teacher_all/homework/data/datasources/teacher_homework_remote_data_source.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';
import 'package:aula360/features/teacher_all/homework/domain/repositories/teacher_homework_repository.dart';

class TeacherHomeworkRepositoryImpl implements TeacherHomeworkRepository {
  final TeacherHomeworkRemoteDataSource _remoteDataSource;

  TeacherHomeworkRepositoryImpl(this._remoteDataSource);

  @override
  Future<TeacherHomeworkDto> createHomework(CreateHomeworkRequestDto payload) {
    return _remoteDataSource.createHomework(payload);
  }

  @override
  Future<PaginatedResult<TeacherHomeworkDto>> getHomework({
    String? cohortId,
    int page = 1,
    int limit = 20,
  }) {
    return _remoteDataSource.getHomework(
      cohortId: cohortId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<HomeworkSubmissionDto> markHomeworkSubmission(
    String homeworkId,
    String studentId,
    MarkHomeworkSubmissionRequestDto payload,
  ) {
    return _remoteDataSource.markHomeworkSubmission(
      homeworkId,
      studentId,
      payload,
    );
  }
}

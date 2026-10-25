import 'package:aula360/core/constants/api_constants.dart';
import 'package:aula360/core/network/api_client.dart';
import 'package:aula360/core/network/api_exception.dart';
import 'package:aula360/features/share/model/pagination_meta_model.dart';
import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';

abstract class TeacherHomeworkRemoteDataSource {
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

class TeacherHomeworkRemoteDataSourceImpl
    implements TeacherHomeworkRemoteDataSource {
  final ApiClient _client;

  TeacherHomeworkRemoteDataSourceImpl(this._client);

  @override
  Future<TeacherHomeworkDto> createHomework(
    CreateHomeworkRequestDto payload,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.teacherHomework,
        data: payload.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final homeworkData = data['data'];
        if (homeworkData is Map<String, dynamic>) {
          return TeacherHomeworkDto.fromJson(homeworkData);
        }
      }

      throw ApiException(
        message: 'Invalid response when creating homework',
        statusCode: response.statusCode ?? 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to create homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PaginatedResult<TeacherHomeworkDto>> getHomework({
    String? cohortId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (cohortId != null && cohortId.isNotEmpty) {
        queryParams['cohortId'] = cohortId;
      }

      final response = await _client.get(
        ApiConstants.teacherHomework,
        queryParameters: queryParams,
      );

      final data = response.data;
      PaginationMeta? meta;
      List<TeacherHomeworkDto> list = [];

      if (data is Map<String, dynamic>) {
        if (data['meta'] is Map<String, dynamic>) {
          meta = PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>);
        }
        final rawList = data['data'];
        if (rawList is List) {
          list = rawList
              .whereType<Map<String, dynamic>>()
              .map(TeacherHomeworkDto.fromJson)
              .toList();
        }
      } else if (data is List) {
        list = data
            .whereType<Map<String, dynamic>>()
            .map(TeacherHomeworkDto.fromJson)
            .toList();
      }

      return PaginatedResult<TeacherHomeworkDto>(
        data: list,
        meta: meta,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch teacher homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<HomeworkSubmissionDto> markHomeworkSubmission(
    String homeworkId,
    String studentId,
    MarkHomeworkSubmissionRequestDto payload,
  ) async {
    try {
      final response = await _client.patch(
        ApiConstants.teacherHomeworkSubmission(homeworkId, studentId),
        data: payload.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final submissionData = data['data'];
        if (submissionData is Map<String, dynamic>) {
          return HomeworkSubmissionDto.fromJson(submissionData);
        }
      }

      throw ApiException(
        message: 'Invalid response when marking homework submission',
        statusCode: response.statusCode ?? 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to mark homework submission: $e',
        statusCode: 500,
      );
    }
  }
}

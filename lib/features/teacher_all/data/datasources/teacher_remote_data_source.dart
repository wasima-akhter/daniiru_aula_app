import 'package:aula360/core/constants/api_constants.dart';
import 'package:aula360/core/network/api_client.dart';
import 'package:aula360/core/network/api_exception.dart';
import '../dtos/attendance_dtos.dart';
import '../dtos/class_session_dto.dart';
import '../dtos/end_session_dtos.dart';
import '../dtos/teacher_homework_dto.dart';
import '../../reports/data/dtos/teacher_report_dto.dart';
import '../../../parent_all/data/dtos/announcement_dto.dart';
import '../../../share/model/pagination_meta_model.dart';
import '../../../share/widgets/paginator/paginator.dart';

abstract class TeacherRemoteDataSource {
  Future<List<ClassSessionDto>> getSessions({DateTime? date});
  Future<ClassSessionDto> getSessionDetail(String sessionId);
  Future<ClassSessionDto> startSession(String sessionId);
  Future<int> takeAttendance(String sessionId, TakeAttendancePayloadDto payload);
  Future<ClassSessionDto> endSession(String sessionId, EndSessionPayloadDto payload);
  Future<void> createHomework(CreateHomeworkRequestDto request);
  Future<List<TeacherHomeworkDto>> getHomework({String? cohortId, int page = 1, int limit = 20});
  Future<HomeworkSubmissionDto> markHomeworkSubmission({
    required String homeworkId,
    required String studentId,
    required MarkHomeworkSubmissionRequestDto request,
  });
  Future<List<TeacherReportDto>> getTeacherReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? cohortId,
  });
  Future<TeacherReportDetailDto> getTeacherReportDetail(String id);
  Future<PaginatedResult<AnnouncementDto>> getAnnouncements({
    int page = 1,
    int limit = 10,
  });
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  final ApiClient _client;

  TeacherRemoteDataSourceImpl(this._client);

  @override
  Future<List<ClassSessionDto>> getSessions({DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        // Backend strictly requires ISO 8601 UTC datetime (e.g. 2026-10-20T00:00:00.000Z).
        // If the date has no time components (calendar date selection), normalize to UTC midnight
        // of that calendar day to prevent timezone shifts across midnight.
        final DateTime utc;
        if (date.hour == 0 && date.minute == 0 && date.second == 0) {
          utc = DateTime.utc(date.year, date.month, date.day);
        } else {
          utc = date.toUtc();
        }
        queryParams['date'] = utc.toIso8601String();
      }

      final response = await _client.get(
        ApiConstants.teacherSessions,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(ClassSessionDto.fromJson)
              .toList();
        }
      } else if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ClassSessionDto.fromJson)
            .toList();
      }

      return const [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch teacher sessions: $e', statusCode: 500);
    }
  }

  @override
  Future<ClassSessionDto> getSessionDetail(String sessionId) async {
    try {
      final response = await _client.get(
        ApiConstants.teacherSessionDetail(sessionId),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          return ClassSessionDto.fromJson(nested);
        }
      }

      throw ApiException(
        message: 'Invalid response fetching session details',
        statusCode: response.statusCode ?? 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch session detail: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ClassSessionDto> startSession(String sessionId) async {
    try {
      final response = await _client.post(
        ApiConstants.teacherSessionStart(sessionId),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          return ClassSessionDto.fromJson(nested);
        }
      }

      throw ApiException(
        message: 'Invalid response starting session',
        statusCode: response.statusCode ?? 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to start session: $e', statusCode: 500);
    }
  }

  @override
  Future<int> takeAttendance(
    String sessionId,
    TakeAttendancePayloadDto payload,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.teacherSessionAttendance(sessionId),
        data: payload.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          return (nested['updatedCount'] as num?)?.toInt() ?? 0;
        }
      }
      return 0;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to record attendance: $e', statusCode: 500);
    }
  }

  @override
  Future<ClassSessionDto> endSession(
    String sessionId,
    EndSessionPayloadDto payload,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.teacherSessionEnd(sessionId),
        data: payload.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          return ClassSessionDto.fromJson(nested);
        }
      }

      throw ApiException(
        message: 'Invalid response ending session',
        statusCode: response.statusCode ?? 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to end session: $e', statusCode: 500);
    }
  }

  @override
  Future<void> createHomework(CreateHomeworkRequestDto request) async {
    try {
      await _client.post(
        ApiConstants.teacherHomework,
        data: request.toJson(),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to create homework: $e', statusCode: 500);
    }
  }

  @override
  Future<List<TeacherHomeworkDto>> getHomework({
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
      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(TeacherHomeworkDto.fromJson)
              .toList();
        }
      }

      return const [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch homework: $e', statusCode: 500);
    }
  }

  @override
  Future<HomeworkSubmissionDto> markHomeworkSubmission({
    required String homeworkId,
    required String studentId,
    required MarkHomeworkSubmissionRequestDto request,
  }) async {
    try {
      final response = await _client.patch(
        ApiConstants.teacherHomeworkSubmission(homeworkId, studentId),
        data: request.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          return HomeworkSubmissionDto.fromJson(nested);
        }
      }

      throw ApiException(
        message: 'Invalid response marking homework submission',
        statusCode: response.statusCode ?? 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to mark homework submission: $e', statusCode: 500);
    }
  }

  @override
  Future<List<TeacherReportDto>> getTeacherReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? cohortId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (cohortId != null && cohortId.isNotEmpty) {
        queryParams['cohortId'] = cohortId;
      }

      final response = await _client.get(
        ApiConstants.teacherReports,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(TeacherReportDto.fromJson)
              .toList();
        }
      } else if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TeacherReportDto.fromJson)
            .toList();
      }

      return const [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch teacher reports: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TeacherReportDetailDto> getTeacherReportDetail(String id) async {
    try {
      final response = await _client.get(
        ApiConstants.teacherReportDetail(id),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final item = data['data'] ?? data;
        if (item is Map<String, dynamic>) {
          return TeacherReportDetailDto.fromJson(item);
        }
      }

      throw ApiException(
        message: 'Invalid teacher report detail payload format',
        statusCode: 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch teacher report detail: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PaginatedResult<AnnouncementDto>> getAnnouncements({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.announcements,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      PaginationMeta? meta;
      List<AnnouncementDto> list = [];

      if (data is Map<String, dynamic>) {
        if (data['meta'] is Map<String, dynamic>) {
          meta = PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>);
        }
        final rawList = data['data'];
        if (rawList is List) {
          list = rawList
              .whereType<Map<String, dynamic>>()
              .map(AnnouncementDto.fromJson)
              .toList();
        }
      } else if (data is List) {
        list = data
            .whereType<Map<String, dynamic>>()
            .map(AnnouncementDto.fromJson)
            .toList();
      }
      return PaginatedResult<AnnouncementDto>(data: list, meta: meta);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch announcements: $e',
        statusCode: 500,
      );
    }
  }
}


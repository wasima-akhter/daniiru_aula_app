import 'package:aula360/features/teacher_all/attendance/data/datasources/teacher_attendance_remote_data_source.dart';
import 'package:aula360/features/teacher_all/attendance/data/dtos/attendance_dtos.dart';
import 'package:aula360/features/teacher_all/attendance/data/dtos/end_session_dtos.dart';
import 'package:aula360/features/teacher_all/attendance/domain/repositories/teacher_attendance_repository.dart';
import 'package:aula360/features/teacher_all/classes/data/dtos/class_session_dto.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';

class TeacherAttendanceRepositoryImpl implements TeacherAttendanceRepository {
  final TeacherAttendanceRemoteDataSource _remoteDataSource;

  TeacherAttendanceRepositoryImpl(this._remoteDataSource);

  List<AttendanceStudent> _attendanceStudents = [];

  @override
  Future<List<AttendanceStudent>> getAttendanceStudents([String? sessionId]) async {
    if (sessionId != null && sessionId.isNotEmpty) {
      try {
        final session = await _remoteDataSource.getSessionDetail(sessionId);
        _attendanceStudents = session.students.map((s) {
          return AttendanceStudent(
            id: s.id,
            name: s.fullName,
            initials: s.initials,
            desk: s.enrollmentNumber.isNotEmpty ? s.enrollmentNumber : 'STU',
            status: TeacherAttendanceStatus.present,
          );
        }).toList();
        return List.from(_attendanceStudents);
      } catch (e) {
        _attendanceStudents = [];
        rethrow;
      }
    }
    return List.from(_attendanceStudents);
  }

  @override
  void updateStudentAttendance(int index, TeacherAttendanceStatus status) {
    if (index >= 0 && index < _attendanceStudents.length) {
      _attendanceStudents[index] = AttendanceStudent(
        id: _attendanceStudents[index].id,
        name: _attendanceStudents[index].name,
        initials: _attendanceStudents[index].initials,
        desk: _attendanceStudents[index].desk,
        status: status,
      );
    }
  }

  @override
  Future<int> takeAttendance(
    String sessionId,
    TakeAttendancePayloadDto payload,
  ) {
    return _remoteDataSource.takeAttendance(sessionId, payload);
  }

  @override
  Future<ClassSessionDto> endSession(
    String sessionId,
    EndSessionPayloadDto payload,
  ) {
    return _remoteDataSource.endSession(sessionId, payload);
  }
}

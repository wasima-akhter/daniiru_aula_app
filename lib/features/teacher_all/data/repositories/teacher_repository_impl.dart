import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aula360/core/network/network_providers.dart';
import '../../../profile/data/dtos/teacher_profile_dto.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../../helper/teacher_enums.dart';
import '../../helper/teacher_models.dart';
import '../datasources/teacher_remote_data_source.dart';
import '../dtos/attendance_dtos.dart';
import '../dtos/class_session_dto.dart';
import '../dtos/end_session_dtos.dart';
import '../dtos/teacher_homework_dto.dart';

import '../../students/data/datasources/teacher_students_remote_data_source.dart';
import '../../students/presentation/providers/teacher_students_providers.dart';
import '../../../parent_all/data/dtos/announcement_dto.dart';
import '../../../share/widgets/paginator/paginator.dart';

final teacherRemoteDataSourceProvider = Provider<TeacherRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return TeacherRemoteDataSourceImpl(client);
});

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepositoryImpl(
    remoteDataSource: ref.watch(teacherRemoteDataSourceProvider),
    studentsRemoteDataSource: ref.watch(teacherStudentsRemoteDataSourceProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherRemoteDataSource? remoteDataSource;
  final TeacherStudentsRemoteDataSource? studentsRemoteDataSource;
  final ProfileRepository? profileRepository;
  final SettingsRepository? settingsRepository;

  TeacherRepositoryImpl({
    this.remoteDataSource,
    this.studentsRemoteDataSource,
    this.profileRepository,
    this.settingsRepository,
  });

  final List<AttendanceStudent> _attendanceStudents = [];
  final List<TeacherReport> _reports = [];

  TeacherProfileData _profile = const TeacherProfileData(
    name: 'Docente Aula 360',
    email: 'teacher@aula360.es',
    phone: '',
  );

  @override
  Future<List<AcademyClass>> getTodayClasses() async {
    if (remoteDataSource != null) {
      final sessions =
          await remoteDataSource!.getSessions(date: DateTime.now());
      return sessions.map((s) {
        final status = s.status == 'ONGOING'
            ? ClassStatus.next
            : ClassStatus.scheduled;

        return AcademyClass(
          id: s.id,
          scheduleId: s.scheduleId,
          time: '${s.startTime} - ${s.endTime}',
          title: s.subjectName,
          subtitle: s.cohortName,
          room: s.classroomRoomNumber,
          group: s.cohortName,
          students: s.students.isNotEmpty ? s.students.length : 24,
          status: status,
          rawStatus: s.status,
          cohortId: s.cohortId,
          subjectId: s.subjectId,
        );
      }).toList();
    }
    return const [];
  }

  @override
  Future<List<AcademyClass>> getUpcomingClasses() async {
    if (remoteDataSource != null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final sessions = await remoteDataSource!.getSessions(date: tomorrow);
      return sessions.map((s) {
        return AcademyClass(
          id: s.id,
          scheduleId: s.scheduleId,
          time: '${s.startTime} - ${s.endTime}',
          title: s.subjectName,
          subtitle: s.cohortName,
          room: s.classroomRoomNumber,
          group: s.cohortName,
          students: s.students.isNotEmpty ? s.students.length : 24,
          status: ClassStatus.scheduled,
          rawStatus: s.status,
          cohortId: s.cohortId,
          subjectId: s.subjectId,
        );
      }).toList();
    }
    return const [];
  }

  @override
  Future<List<HomeScheduleItem>> getHomeSchedule() async {
    if (remoteDataSource != null) {
      final sessions =
          await remoteDataSource!.getSessions(date: DateTime.now());
      return sessions.map((s) {
        return HomeScheduleItem(
          id: s.id,
          scheduleId: s.scheduleId,
          startTime: s.startTime,
          endTime: s.endTime,
          title: s.subjectName,
          subtitle: s.cohortName,
          room: s.classroomRoomNumber,
          group: s.cohortName,
          students: 24,
          type: s.status == 'ONGOING'
              ? HomeClassType.next
              : HomeClassType.scheduled,
          rawStatus: s.status,
        );
      }).toList();
    }
    return const [];
  }

  @override
  Future<List<TeacherStudent>> getStudents() async {
    if (studentsRemoteDataSource != null) {
      try {
        final roster = await studentsRemoteDataSource!.getStudents();
        return roster.map((dto) => dto.toTeacherStudent()).toList();
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  @override
  Future<TeacherStudent> getStudentDetail(String id) async {
    if (studentsRemoteDataSource != null) {
      final dto = await studentsRemoteDataSource!.getStudentDetail(id);
      return TeacherStudent(
        id: dto.id,
        name: dto.fullName,
        group: StudentGroup.groupA,
        room: dto.gradeLevel ?? 'Aula 1',
        desk: dto.enrollmentNumber,
        attendance: dto.attendancePercentage.toInt(),
        status: dto.attendancePercentage >= 80 ? StudentStatus.present : StudentStatus.needsCheckIn,
        initials: dto.initials,
        avatarUrl: dto.avatarUrl,
        gradeLevel: dto.gradeLevel,
        enrollmentNumber: dto.enrollmentNumber,
      );
    }
    throw UnsupportedError('Remote student data source not available');
  }

  @override
  Future<List<AttendanceStudent>> getAttendanceStudents() async {
    return List.from(_attendanceStudents);
  }

  @override
  Future<void> updateStudentAttendance(
    int index,
    TeacherAttendanceStatus status,
  ) async {
    if (index >= 0 && index < _attendanceStudents.length) {
      _attendanceStudents[index].status = status;
    }
  }

  @override
  Future<List<TeacherReport>> getReports() async {
    final list = <TeacherReport>[..._reports];
    final remote = remoteDataSource;
    if (remote != null) {
      try {
        final sessions = await remote.getSessions();
        for (final s in sessions) {
          if (s.status == 'COMPLETED') {
            final dateStr = s.sessionDate.length >= 10
                ? s.sessionDate.substring(0, 10)
                : s.sessionDate;
            list.add(
              TeacherReport(
                category: ReportCategory.classReport,
                group: StudentGroup.groupA,
                room: s.classroomRoomNumber,
                title: s.subjectName,
                subtitle: s.cohortName,
                date: dateStr,
                time: '${s.startTime} - ${s.endTime}',
                status: ReportStatus.submitted,
              ),
            );
          }
        }
      } catch (_) {}
    }
    return list;
  }

  @override
  Future<void> submitReport(TeacherReport report) async {
    _reports.insert(0, report);
  }

  @override
  Future<TeacherProfileData> getProfile() async {
    final repo = profileRepository;
    if (repo != null) {
      try {
        final entity = await repo.getTeacherProfile();
        _profile = TeacherProfileData(
          id: entity.userId,
          name: entity.fullName,
          email: entity.email,
          phone: entity.phone,
          department: entity.department ?? _profile.department,
          designation: entity.designation ?? _profile.designation,
          bio: entity.bio ?? _profile.bio,
          language: entity.language,
          profileImagePath: entity.avatarUrl ?? _profile.profileImagePath,
        );
        return _profile;
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return _profile;
  }

  @override
  Future<void> updateProfile(TeacherProfileData profile) async {
    final repo = profileRepository;
    if (repo != null) {
      try {
        final dto = UpdateTeacherProfileDto(
          fullName: profile.name,
          phone: profile.phone,
          avatarUrl: profile.profileImagePath,
          department: profile.department,
          designation: profile.designation,
          bio: profile.bio,
        );
        final entity = await repo.updateTeacherProfile(dto);
        _profile = profile.copyWith(
          name: entity.fullName,
          email: entity.email,
          phone: entity.phone,
          department: entity.department,
          designation: entity.designation,
          bio: entity.bio,
          language: entity.language,
          profileImagePath: entity.avatarUrl,
        );
        return;
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = profile;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final repo = settingsRepository;
    if (repo != null) {
      await repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return;
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ==========================================
  // REAL OPENAPI BACKEND ENDPOINTS
  // ==========================================

  @override
  Future<List<ClassSessionDto>> getTeacherSessions({DateTime? date}) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.getSessions(date: date);
    }
    return const [];
  }

  @override
  Future<ClassSessionDto> getSessionDetail(String sessionId) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.getSessionDetail(sessionId);
    }
    throw UnsupportedError('Remote data source not available');
  }

  @override
  Future<ClassSessionDto> startSession(String sessionId) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.startSession(sessionId);
    }
    throw UnsupportedError('Remote data source not available');
  }

  @override
  Future<int> takeSessionAttendance(
    String sessionId,
    TakeAttendancePayloadDto payload,
  ) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.takeAttendance(sessionId, payload);
    }
    return 0;
  }

  @override
  Future<ClassSessionDto> endSessionAndSubmitReport(
    String sessionId,
    EndSessionPayloadDto payload,
  ) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.endSession(sessionId, payload);
    }
    throw UnsupportedError('Remote data source not available');
  }

  @override
  Future<void> createHomework(CreateHomeworkRequestDto request) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.createHomework(request);
    }
  }

  @override
  Future<List<TeacherHomeworkDto>> getHomeworkList({
    String? cohortId,
    int page = 1,
    int limit = 20,
  }) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.getHomework(
        cohortId: cohortId,
        page: page,
        limit: limit,
      );
    }
    return const [];
  }

  @override
  Future<HomeworkSubmissionDto> markHomeworkSubmission({
    required String homeworkId,
    required String studentId,
    required MarkHomeworkSubmissionRequestDto request,
  }) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.markHomeworkSubmission(
        homeworkId: homeworkId,
        studentId: studentId,
        request: request,
      );
    }
    throw UnsupportedError('Remote data source not available');
  }

  @override
  Future<PaginatedResult<AnnouncementDto>> getAnnouncements({
    int page = 1,
    int limit = 10,
  }) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.getAnnouncements(
        page: page,
        limit: limit,
      );
    }
    return const PaginatedResult<AnnouncementDto>(data: [], meta: null);
  }
}


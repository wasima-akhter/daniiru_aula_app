import 'package:aula360/core/localization/localization_meta.dart';
import 'package:aula360/core/localization/pending_refetch_controller.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';

class SessionDetailStudentDto {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String enrollmentNumber;
  final String? attendanceStatus;
  final LocalizationMeta? localization;

  const SessionDetailStudentDto({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.enrollmentNumber,
    this.attendanceStatus,
    this.localization,
  });

  factory SessionDetailStudentDto.fromJson(Map<String, dynamic> json) {
    return SessionDetailStudentDto(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      enrollmentNumber: json['enrollmentNumber'] as String? ?? '',
      attendanceStatus: json['attendanceStatus'] as String?,
      localization: LocalizationMeta.tryParse(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'enrollmentNumber': enrollmentNumber,
        if (attendanceStatus != null) 'attendanceStatus': attendanceStatus,
      };

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '--';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class ClassSessionDto {
  final String id;
  final String scheduleId;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? entryTime;
  final String? exitTime;
  final String subjectName;
  final String? subjectId;
  final String? cohortId;
  final String cohortName;
  final String teacherName;
  final String classroomRoomNumber;
  final bool hasReport;
  final bool hasHomework;
  final bool hasAttendance;
  final List<SessionDetailStudentDto> students;
  final Map<String, dynamic>? report;
  final List<dynamic>? homework;
  final LocalizationMeta? localization;

  const ClassSessionDto({
    required this.id,
    required this.scheduleId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.entryTime,
    this.exitTime,
    required this.subjectName,
    this.subjectId,
    this.cohortId,
    required this.cohortName,
    required this.teacherName,
    required this.classroomRoomNumber,
    this.hasReport = false,
    this.hasHomework = false,
    this.hasAttendance = false,
    this.students = const [],
    this.report,
    this.homework,
    this.localization,
  });

  factory ClassSessionDto.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['students'];
    final parsedStudents = <SessionDetailStudentDto>[];
    if (rawStudents is List) {
      for (final s in rawStudents) {
        if (s is Map<String, dynamic>) {
          parsedStudents.add(SessionDetailStudentDto.fromJson(s));
        }
      }
    }

    final rawHomework = json['homework'];

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    bool isUuid(String? str) => str != null && uuidRegex.hasMatch(str.trim());

    String? subjectId = (json['subjectId'] as String?) ??
        (json['subject_id'] as String?) ??
        (json['subjectUUID'] as String?) ??
        (json['subject'] is Map
            ? (json['subject']['id'] as String? ??
                json['subject']['uuid'] as String?)
            : null) ??
        (json['subject'] is String && isUuid(json['subject'] as String)
            ? json['subject'] as String
            : null) ??
        (json['schedule'] is Map
            ? (json['schedule']['subjectId'] as String? ??
                json['schedule']['subject_id'] as String?)
            : null) ??
        (json['schedule'] is Map && json['schedule']['subject'] is Map
            ? (json['schedule']['subject']['id'] as String? ??
                json['schedule']['subject']['uuid'] as String?)
            : null) ??
        (json['schedule'] is Map &&
                json['schedule']['subject'] is String &&
                isUuid(json['schedule']['subject'] as String)
            ? json['schedule']['subject'] as String
            : null);
    final rawScheduleId = json['scheduleId'] as String? ??
        (json['schedule_id'] as String?) ??
        (json['schedule'] is Map ? json['schedule']['id'] as String? : null) ??
        '';

    if ((subjectId == null || subjectId.isEmpty) &&
        rawHomework is List &&
        rawHomework.isNotEmpty) {
      for (final hw in rawHomework) {
        if (hw is Map &&
            hw['subjectId'] is String &&
            (hw['subjectId'] as String).isNotEmpty) {
          subjectId = hw['subjectId'] as String;
          break;
        }
      }
    }

    if ((subjectId == null || subjectId.isEmpty) && rawScheduleId.isNotEmpty) {
      subjectId = rawScheduleId;
    }

    String? cohortId = (json['cohortId'] as String?) ??
        (json['cohort_id'] as String?) ??
        (json['cohortUUID'] as String?) ??
        (json['cohort'] is Map
            ? (json['cohort']['id'] as String? ??
                json['cohort']['uuid'] as String?)
            : null) ??
        (json['cohort'] is String && isUuid(json['cohort'] as String)
            ? json['cohort'] as String
            : null) ??
        (json['schedule'] is Map
            ? (json['schedule']['cohortId'] as String? ??
                json['schedule']['cohort_id'] as String?)
            : null) ??
        (json['schedule'] is Map && json['schedule']['cohort'] is Map
            ? (json['schedule']['cohort']['id'] as String? ??
                json['schedule']['cohort']['uuid'] as String?)
            : null) ??
        (json['schedule'] is Map &&
                json['schedule']['cohort'] is String &&
                isUuid(json['schedule']['cohort'] as String)
            ? json['schedule']['cohort'] as String
            : null);
    if ((cohortId == null || cohortId.isEmpty) &&
        rawHomework is List &&
        rawHomework.isNotEmpty) {
      for (final hw in rawHomework) {
        if (hw is Map &&
            hw['cohortId'] is String &&
            (hw['cohortId'] as String).isNotEmpty) {
          cohortId = hw['cohortId'] as String;
          break;
        }
      }
    }

    final parsedSubjectName = (json['subjectName'] as String?) ??
        (json['subject'] is Map ? json['subject']['name'] as String? : null) ??
        (json['schedule'] is Map
            ? (json['schedule']['subjectName'] as String? ??
                (json['schedule']['subject'] is Map
                    ? json['schedule']['subject']['name'] as String?
                    : null))
            : null) ??
        '';

    final parsedCohortName = (json['cohortName'] as String?) ??
        (json['cohort'] is Map ? json['cohort']['name'] as String? : null) ??
        (json['schedule'] is Map
            ? (json['schedule']['cohortName'] as String? ??
                (json['schedule']['cohort'] is Map
                    ? json['schedule']['cohort']['name'] as String?
                    : null))
            : null) ??
        '';

    return ClassSessionDto(
      id: json['id'] as String? ?? '',
      scheduleId: rawScheduleId,
      sessionDate: json['sessionDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? 'SCHEDULED',
      entryTime: json['entryTime'] as String?,
      exitTime: json['exitTime'] as String?,
      subjectName: parsedSubjectName,
      subjectId: subjectId,
      cohortId: cohortId,
      cohortName: parsedCohortName,
      teacherName: json['teacherName'] as String? ?? '',
      classroomRoomNumber: json['classroomRoomNumber'] as String? ?? '',
      hasReport: json['hasReport'] as bool? ?? false,
      hasHomework: json['hasHomework'] as bool? ?? false,
      hasAttendance: json['hasAttendance'] as bool? ?? false,
      students: parsedStudents,
      report: json['report'] is Map<String, dynamic>
          ? json['report'] as Map<String, dynamic>
          : null,
      homework:
          json['homework'] is List ? json['homework'] as List<dynamic> : null,
      localization: LocalizationMeta.tryParse(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'sessionDate': sessionDate,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      if (entryTime != null) 'entryTime': entryTime,
      if (exitTime != null) 'exitTime': exitTime,
      'subjectName': subjectName,
      if (subjectId != null) 'subjectId': subjectId,
      if (cohortId != null) 'cohortId': cohortId,
      'cohortName': cohortName,
      'teacherName': teacherName,
      'classroomRoomNumber': classroomRoomNumber,
      'hasReport': hasReport,
      'hasHomework': hasHomework,
      'hasAttendance': hasAttendance,
      'students': students.map((s) => s.toJson()).toList(),
      if (report != null) 'report': report,
      if (homework != null) 'homework': homework,
    };
  }

  LocalizationMeta? get reportLocalization =>
      report != null ? LocalizationMeta.tryParse(report!) : null;

  List<LocalizationMeta?> get homeworkLocalizations {
    final list = homework;
    if (list == null) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) LocalizationMeta.tryParse(item),
    ];
  }

  /// True when the root session OR any nested student/report/homework entry
  /// has a `PENDING` or `PROCESSING` backend translation job.
  bool get hasAnyPendingLocalization => anyLocalizationPending([
        localization,
        ...students.map((s) => s.localization),
        reportLocalization,
        ...homeworkLocalizations,
      ]);

  String get formattedTime => (startTime.isNotEmpty && endTime.isNotEmpty)
      ? '$startTime - $endTime'
      : startTime;

  AcademyClass toAcademyClass() {
    final classStatus = status == 'ONGOING'
        ? ClassStatus.next
        : ClassStatus.scheduled;

    return AcademyClass(
      id: id,
      scheduleId: scheduleId,
      time: formattedTime,
      title: subjectName,
      subtitle: cohortName,
      room: classroomRoomNumber,
      group: cohortName,
      students: students.length,
      status: classStatus,
      rawStatus: status,
      cohortId: cohortId,
      subjectId: subjectId,
      localization: localization,
    );
  }
}

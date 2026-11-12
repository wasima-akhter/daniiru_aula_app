import 'package:aula360/core/localization/localization_meta.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';

class TeacherReportStudentAttendanceDto {
  final String studentId;
  final String studentName;
  final String? avatarUrl;
  final String status;

  const TeacherReportStudentAttendanceDto({
    required this.studentId,
    required this.studentName,
    this.avatarUrl,
    required this.status,
  });

  factory TeacherReportStudentAttendanceDto.fromJson(Map<String, dynamic> json) {
    return TeacherReportStudentAttendanceDto(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'PRESENT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'avatarUrl': avatarUrl,
      'status': status,
    };
  }
}

class TeacherReportAttendanceSummaryDto {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int excused;

  const TeacherReportAttendanceSummaryDto({
    this.total = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.excused = 0,
  });

  factory TeacherReportAttendanceSummaryDto.fromJson(Map<String, dynamic> json) {
    return TeacherReportAttendanceSummaryDto(
      total: (json['total'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'present': present,
      'absent': absent,
      'late': late,
      'excused': excused,
    };
  }
}

class TeacherReportDto {
  final String id;
  final String sessionId;
  final String sessionDate;
  final String cohortId;
  final String cohortName;
  final String subjectId;
  final String subjectName;
  final String contentCovered;
  final String homeworkAssigned;
  final String attitudeRating;
  final String workEffortRating;
  final String observations;
  final String status;
  final String submittedAt;
  final String? reviewedAt;
  final String? reviewNote;
  final LocalizationMeta? localization;

  const TeacherReportDto({
    required this.id,
    required this.sessionId,
    required this.sessionDate,
    required this.cohortId,
    required this.cohortName,
    required this.subjectId,
    required this.subjectName,
    required this.contentCovered,
    required this.homeworkAssigned,
    required this.attitudeRating,
    required this.workEffortRating,
    required this.observations,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
    this.localization,
  });

  factory TeacherReportDto.fromJson(Map<String, dynamic> json) {
    return TeacherReportDto(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      sessionDate: json['sessionDate'] as String? ?? '',
      cohortId: json['cohortId'] as String? ?? '',
      cohortName: json['cohortName'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      contentCovered: json['contentCovered'] as String? ?? '',
      homeworkAssigned: json['homeworkAssigned'] as String? ?? '',
      attitudeRating: json['attitudeRating'] as String? ?? 'SATISFACTORY',
      workEffortRating: json['workEffortRating'] as String? ?? 'ON_TRACK',
      observations: json['observations'] as String? ?? '',
      status: json['status'] as String? ?? 'SUBMITTED',
      submittedAt: json['submittedAt'] as String? ?? '',
      reviewedAt: json['reviewedAt'] as String?,
      reviewNote: json['reviewNote'] as String?,
      localization: LocalizationMeta.tryParse(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'sessionDate': sessionDate,
      'cohortId': cohortId,
      'cohortName': cohortName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'contentCovered': contentCovered,
      'homeworkAssigned': homeworkAssigned,
      'attitudeRating': attitudeRating,
      'workEffortRating': workEffortRating,
      'observations': observations,
      'status': status,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'reviewNote': reviewNote,
    };
  }

  TeacherReport toModel() {
    final dateStr = sessionDate.length >= 10
        ? sessionDate.substring(0, 10)
        : (submittedAt.length >= 10 ? submittedAt.substring(0, 10) : sessionDate);

    final timeStr = submittedAt.length >= 16
        ? submittedAt.substring(11, 16)
        : '';

    final isReviewed = status.toUpperCase() == 'REVIEWED';

    return TeacherReport(
      id: id,
      sessionId: sessionId,
      cohortId: cohortId,
      cohortName: cohortName,
      subjectId: subjectId,
      subjectName: subjectName,
      title: subjectName.isNotEmpty ? subjectName : 'Class Report',
      subtitle: cohortName,
      date: dateStr,
      time: timeStr.isNotEmpty ? timeStr : 'Session Report',
      category: ReportCategory.classReport,
      group: cohortName.toLowerCase().contains('b')
          ? StudentGroup.groupB
          : StudentGroup.groupA,
      status: isReviewed ? ReportStatus.reviewed : ReportStatus.submitted,
      rawStatus: status,
      contentCovered: contentCovered,
      homeworkAssigned: homeworkAssigned,
      attitudeRating: attitudeRating,
      workEffortRating: workEffortRating,
      observations: observations,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      reviewNote: reviewNote,
      localization: localization,
    );
  }
}

class TeacherReportDetailDto {
  final String id;
  final String sessionId;
  final String sessionDate;
  final String cohortId;
  final String cohortName;
  final String subjectId;
  final String subjectName;
  final String contentCovered;
  final String homeworkAssigned;
  final String attitudeRating;
  final String workEffortRating;
  final String observations;
  final String status;
  final String submittedAt;
  final String? reviewedAt;
  final String? reviewNote;
  final String? startTime;
  final String? endTime;
  final String? entryTime;
  final String? exitTime;
  final List<TeacherReportStudentAttendanceDto> attendances;
  final TeacherReportAttendanceSummaryDto? attendanceSummary;
  final LocalizationMeta? localization;

  const TeacherReportDetailDto({
    required this.id,
    required this.sessionId,
    required this.sessionDate,
    required this.cohortId,
    required this.cohortName,
    required this.subjectId,
    required this.subjectName,
    required this.contentCovered,
    required this.homeworkAssigned,
    required this.attitudeRating,
    required this.workEffortRating,
    required this.observations,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
    this.startTime,
    this.endTime,
    this.entryTime,
    this.exitTime,
    this.attendances = const [],
    this.attendanceSummary,
    this.localization,
  });

  factory TeacherReportDetailDto.fromJson(Map<String, dynamic> json) {
    final rawAttendances = json['attendances'];
    final parsedAttendances = <TeacherReportStudentAttendanceDto>[];
    if (rawAttendances is List) {
      for (final a in rawAttendances) {
        if (a is Map<String, dynamic>) {
          parsedAttendances.add(TeacherReportStudentAttendanceDto.fromJson(a));
        }
      }
    }

    TeacherReportAttendanceSummaryDto? summary;
    if (json['attendanceSummary'] is Map<String, dynamic>) {
      summary = TeacherReportAttendanceSummaryDto.fromJson(
        json['attendanceSummary'] as Map<String, dynamic>,
      );
    }

    return TeacherReportDetailDto(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      sessionDate: json['sessionDate'] as String? ?? '',
      cohortId: json['cohortId'] as String? ?? '',
      cohortName: json['cohortName'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      contentCovered: json['contentCovered'] as String? ?? '',
      homeworkAssigned: json['homeworkAssigned'] as String? ?? '',
      attitudeRating: json['attitudeRating'] as String? ?? 'SATISFACTORY',
      workEffortRating: json['workEffortRating'] as String? ?? 'ON_TRACK',
      observations: json['observations'] as String? ?? '',
      status: json['status'] as String? ?? 'SUBMITTED',
      submittedAt: json['submittedAt'] as String? ?? '',
      reviewedAt: json['reviewedAt'] as String?,
      reviewNote: json['reviewNote'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      entryTime: json['entryTime'] as String?,
      exitTime: json['exitTime'] as String?,
      attendances: parsedAttendances,
      attendanceSummary: summary,
      localization: LocalizationMeta.tryParse(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'sessionDate': sessionDate,
      'cohortId': cohortId,
      'cohortName': cohortName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'contentCovered': contentCovered,
      'homeworkAssigned': homeworkAssigned,
      'attitudeRating': attitudeRating,
      'workEffortRating': workEffortRating,
      'observations': observations,
      'status': status,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'reviewNote': reviewNote,
      'startTime': startTime,
      'endTime': endTime,
      'entryTime': entryTime,
      'exitTime': exitTime,
      'attendances': attendances.map((a) => a.toJson()).toList(),
      'attendanceSummary': attendanceSummary?.toJson(),
    };
  }

  TeacherReport toModel() {
    final dateStr = sessionDate.length >= 10
        ? sessionDate.substring(0, 10)
        : (submittedAt.length >= 10 ? submittedAt.substring(0, 10) : sessionDate);

    final timeStr = (startTime != null && endTime != null)
        ? '$startTime - $endTime'
        : (submittedAt.length >= 16 ? submittedAt.substring(11, 16) : '');

    final isReviewed = status.toUpperCase() == 'REVIEWED';

    return TeacherReport(
      id: id,
      sessionId: sessionId,
      cohortId: cohortId,
      cohortName: cohortName,
      subjectId: subjectId,
      subjectName: subjectName,
      title: subjectName.isNotEmpty ? subjectName : 'Class Report',
      subtitle: cohortName,
      date: dateStr,
      time: timeStr.isNotEmpty ? timeStr : 'Session Report',
      category: ReportCategory.classReport,
      group: cohortName.toLowerCase().contains('b')
          ? StudentGroup.groupB
          : StudentGroup.groupA,
      status: isReviewed ? ReportStatus.reviewed : ReportStatus.submitted,
      rawStatus: status,
      contentCovered: contentCovered,
      homeworkAssigned: homeworkAssigned,
      attitudeRating: attitudeRating,
      workEffortRating: workEffortRating,
      observations: observations,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      reviewNote: reviewNote,
      startTime: startTime,
      endTime: endTime,
      entryTime: entryTime,
      exitTime: exitTime,
      attendances: attendances,
      attendanceSummary: attendanceSummary,
      localization: localization,
    );
  }
}

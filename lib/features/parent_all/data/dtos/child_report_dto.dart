import 'package:intl/intl.dart';

import '../../../../core/localization/localization_meta.dart';
import '../../../../core/service/language/language_provider.dart';
import '../../domain/models/parent_models.dart';

class ChildReportDto {
  final String id;
  final String date;
  final String subjectName;
  final String teacherName;
  final String contentCovered;
  final String? observations;
  final String attitudeRating;
  final String workEffortRating;
  final LocalizationMeta? localization;

  const ChildReportDto({
    required this.id,
    required this.date,
    required this.subjectName,
    required this.teacherName,
    required this.contentCovered,
    this.observations,
    required this.attitudeRating,
    required this.workEffortRating,
    this.localization,
  });

  factory ChildReportDto.fromJson(Map<String, dynamic> json) {
    return ChildReportDto(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      contentCovered: json['contentCovered'] as String? ?? '',
      observations: json['observations'] as String?,
      attitudeRating: json['attitudeRating'] as String? ?? 'SATISFACTORY',
      workEffortRating: json['workEffortRating'] as String? ?? 'ON_TRACK',
      localization: LocalizationMeta.tryParse(json),
    );
  }

  ReportModel toModel([String? languageCode]) {
    DateTime? dt = DateTime.tryParse(date);
    final dateLabel = dt != null
        ? DateFormat('EEEE, d MMM').format(dt).toUpperCase()
        : date.toUpperCase();

    String initials = 'DOC';
    if (teacherName.trim().isNotEmpty) {
      final parts = teacherName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = teacherName.substring(0, 1).toUpperCase();
      }
    }

    final effectiveLang = languageCode ?? LanguageNotifier.activeLanguageCode;
    final isSpanish = effectiveLang.toLowerCase().startsWith('es');

    final obsLabel = isSpanish ? 'Observaciones' : 'Observations';
    final note = observations != null && observations!.isNotEmpty
        ? '$contentCovered\n\n$obsLabel: $observations'
        : contentCovered;

    final statusText = isSpanish
        ? (attitudeRating == 'EXCELLENT' ? 'Sobresaliente' : 'Satisfactorio')
        : (attitudeRating == 'EXCELLENT' ? 'Outstanding' : 'Satisfactory');

    return ReportModel(
      id: id,
      dateLabel: dateLabel,
      date: dt,
      subject: subjectName,
      teacher: teacherName,
      time: dt != null ? DateFormat('HH:mm').format(dt) : '10:00',
      category: subjectName,
      status: statusText,
      note: note,
      initials: initials,
      localization: localization,
    );
  }
}

class ChildReportDetailDto {
  final String id;
  final String reportDate;
  final String subjectName;
  final String? cohortName;
  final String teacherName;
  final String? classroomRoomNumber;
  final String? startTime;
  final String? endTime;
  final String? contentCovered;
  final String? homeworkAssigned;
  final String? observations;
  final String? attitudeRating;
  final String? workEffortRating;
  final String? studentAttendanceStatus;
  final String? submittedAt;
  final String? reviewedAt;
  final LocalizationMeta? localization;

  const ChildReportDetailDto({
    required this.id,
    required this.reportDate,
    required this.subjectName,
    this.cohortName,
    required this.teacherName,
    this.classroomRoomNumber,
    this.startTime,
    this.endTime,
    this.contentCovered,
    this.homeworkAssigned,
    this.observations,
    this.attitudeRating,
    this.workEffortRating,
    this.studentAttendanceStatus,
    this.submittedAt,
    this.reviewedAt,
    this.localization,
  });

  factory ChildReportDetailDto.fromJson(Map<String, dynamic> json) {
    return ChildReportDetailDto(
      id: json['id'] as String? ?? '',
      reportDate: json['reportDate'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      cohortName: json['cohortName'] as String?,
      teacherName: json['teacherName'] as String? ?? '',
      classroomRoomNumber: json['classroomRoomNumber'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      contentCovered: json['contentCovered'] as String?,
      homeworkAssigned: json['homeworkAssigned'] as String?,
      observations: json['observations'] as String?,
      attitudeRating: json['attitudeRating'] as String?,
      workEffortRating: json['workEffortRating'] as String?,
      studentAttendanceStatus: json['studentAttendanceStatus'] as String?,
      submittedAt: json['submittedAt'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      localization: LocalizationMeta.tryParse(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportDate': reportDate,
      'subjectName': subjectName,
      if (cohortName != null) 'cohortName': cohortName,
      'teacherName': teacherName,
      if (classroomRoomNumber != null) 'classroomRoomNumber': classroomRoomNumber,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (contentCovered != null) 'contentCovered': contentCovered,
      if (homeworkAssigned != null) 'homeworkAssigned': homeworkAssigned,
      if (observations != null) 'observations': observations,
      if (attitudeRating != null) 'attitudeRating': attitudeRating,
      if (workEffortRating != null) 'workEffortRating': workEffortRating,
      if (studentAttendanceStatus != null)
        'studentAttendanceStatus': studentAttendanceStatus,
      if (submittedAt != null) 'submittedAt': submittedAt,
      if (reviewedAt != null) 'reviewedAt': reviewedAt,
    };
  }

  ReportModel toReportModel([String? languageCode]) {
    DateTime? dt = DateTime.tryParse(reportDate);
    final dateLabel = dt != null
        ? DateFormat('EEEE, d MMM').format(dt).toUpperCase()
        : reportDate.toUpperCase();

    String initials = 'DOC';
    if (teacherName.trim().isNotEmpty) {
      final parts = teacherName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = teacherName.substring(0, 1).toUpperCase();
      }
    }

    final effectiveLang = languageCode ?? LanguageNotifier.activeLanguageCode;
    final isSpanish = effectiveLang.toLowerCase().startsWith('es');

    final obsLabel = isSpanish ? 'Observaciones' : 'Observations';
    final note = observations != null && observations!.isNotEmpty
        ? (contentCovered != null && contentCovered!.isNotEmpty
            ? '$contentCovered\n\n$obsLabel: $observations'
            : observations!)
        : (contentCovered ?? '');

    String timeStr = '10:00';
    if (startTime != null && endTime != null && startTime!.isNotEmpty && endTime!.isNotEmpty) {
      timeStr = '$startTime - $endTime';
    } else if (startTime != null && startTime!.isNotEmpty) {
      timeStr = startTime!;
    } else if (dt != null) {
      timeStr = DateFormat('HH:mm').format(dt);
    }

    final statusText = isSpanish
        ? ((attitudeRating?.toUpperCase() == 'EXCELLENT')
            ? 'Sobresaliente'
            : 'Satisfactorio')
        : ((attitudeRating?.toUpperCase() == 'EXCELLENT')
            ? 'Outstanding'
            : 'Satisfactory');

    return ReportModel(
      id: id,
      dateLabel: dateLabel,
      date: dt,
      subject: subjectName,
      teacher: teacherName,
      time: timeStr,
      category: subjectName,
      status: studentAttendanceStatus ?? statusText,
      note: note,
      initials: initials,
      localization: localization,
    );
  }
}


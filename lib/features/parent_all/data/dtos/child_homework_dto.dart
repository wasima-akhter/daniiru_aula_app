import 'package:intl/intl.dart';

import '../../../../core/localization/localization_meta.dart';
import '../../domain/models/parent_models.dart';

class ChildHomeworkDto {
  final String id;
  final String title;
  final String? description;
  final String subjectName;
  final String? teacherName;
  final String? period;
  final String dueDate;
  final String status;
  final String sourceLocale;
  final String displayedLocale;
  final bool isTranslated;
  final String translationStatus;

  const ChildHomeworkDto({
    required this.id,
    required this.title,
    this.description,
    required this.subjectName,
    this.teacherName,
    this.period,
    required this.dueDate,
    required this.status,
    this.sourceLocale = 'en',
    this.displayedLocale = 'en',
    this.isTranslated = false,
    this.translationStatus = 'READY',
  });

  factory ChildHomeworkDto.fromJson(Map<String, dynamic> json) {
    final meta = LocalizationMeta.parseOrDefault(json);
    return ChildHomeworkDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      subjectName: json['subjectName'] as String? ?? '',
      teacherName: json['teacherName'] as String?,
      period: json['period'] as String?,
      dueDate: json['dueDate'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      sourceLocale: meta.sourceLocale,
      displayedLocale: meta.displayedLocale,
      isTranslated: meta.isTranslated,
      translationStatus: meta.translationStatus,
    );
  }

  HomeworkModel toModel() {
    DateTime? dt = DateTime.tryParse(dueDate);
    final deadline = dt != null ? DateFormat('d MMM').format(dt) : dueDate;
    final time = dt != null ? DateFormat('HH:mm').format(dt) : '23:59';

    final isCompleted = status.toUpperCase() == 'COMPLETED';

    return HomeworkModel(
      id: id,
      subject: subjectName,
      teacher: teacherName ?? '',
      period: period ?? '',
      title: title,
      description: description ?? '',
      status: isCompleted ? HomeworkStatus.completed : HomeworkStatus.pending,
      deadline: deadline,
      time: time,
      sourceLocale: sourceLocale,
      displayedLocale: displayedLocale,
      isTranslated: isTranslated,
      translationStatus: translationStatus,
    );
  }
}

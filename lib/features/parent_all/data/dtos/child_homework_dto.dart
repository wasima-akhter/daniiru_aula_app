import 'package:intl/intl.dart';

import '../../domain/models/parent_models.dart';

class ChildHomeworkDto {
  final String id;
  final String title;
  final String? description;
  final String subjectName;
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
    required this.dueDate,
    required this.status,
    this.sourceLocale = 'en',
    this.displayedLocale = 'en',
    this.isTranslated = false,
    this.translationStatus = 'READY',
  });

  factory ChildHomeworkDto.fromJson(Map<String, dynamic> json) {
    return ChildHomeworkDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      subjectName: json['subjectName'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      sourceLocale: json['sourceLocale'] as String? ?? 'en',
      displayedLocale: json['displayedLocale'] as String? ?? 'en',
      isTranslated: json['isTranslated'] as bool? ?? false,
      translationStatus: json['translationStatus'] as String? ?? 'READY',
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
      teacher: 'Profesor titular',
      period: 'Trimestre 1',
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

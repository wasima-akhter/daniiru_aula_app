import '../../../../core/localization/localization_meta.dart';

class ChildProgressDto {
  final num attendancePercentage;
  final num homeworkCompletionPercentage;
  final List<String> subjects;
  final LocalizationMeta? localization;

  const ChildProgressDto({
    required this.attendancePercentage,
    required this.homeworkCompletionPercentage,
    required this.subjects,
    this.localization,
  });

  factory ChildProgressDto.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'];
    List<String> parsedSubjects = [];
    if (rawSubjects is List) {
      parsedSubjects = rawSubjects
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return ChildProgressDto(
      attendancePercentage: json['attendancePercentage'] as num? ?? 0,
      homeworkCompletionPercentage: json['homeworkCompletionPercentage'] as num? ?? 0,
      subjects: parsedSubjects,
      localization: LocalizationMeta.tryParse(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendancePercentage': attendancePercentage,
      'homeworkCompletionPercentage': homeworkCompletionPercentage,
      'subjects': subjects,
    };
  }
}

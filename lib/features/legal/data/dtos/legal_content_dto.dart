import '../../../../core/localization/localization_meta.dart';
import '../../domain/entities/legal_content.dart';

class LegalContentDto {
  final String legalContentType;
  final String content;
  final String? updatedAt;
  final String sourceLocale;
  final String displayedLocale;
  final bool isTranslated;
  final String translationStatus;

  const LegalContentDto({
    required this.legalContentType,
    required this.content,
    this.updatedAt,
    this.sourceLocale = 'en',
    this.displayedLocale = 'en',
    this.isTranslated = false,
    this.translationStatus = 'READY',
  });

  factory LegalContentDto.fromJson(Map<String, dynamic> json) {
    final meta = LocalizationMeta.parseOrDefault(json);
    return LegalContentDto(
      legalContentType:
          json['legalContentType'] as String? ?? 'TERMS_AND_CONDITION',
      content: json['content'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      sourceLocale: meta.sourceLocale,
      displayedLocale: meta.displayedLocale,
      isTranslated: meta.isTranslated,
      translationStatus: meta.translationStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legalContentType': legalContentType,
      'content': content,
      if (updatedAt != null) 'updatedAt': updatedAt,
      'sourceLocale': sourceLocale,
      'displayedLocale': displayedLocale,
      'isTranslated': isTranslated,
      'translationStatus': translationStatus,
    };
  }

  LegalContent toEntity() {
    DateTime? parsedDate;
    if (updatedAt != null) {
      parsedDate = DateTime.tryParse(updatedAt!);
    }

    return LegalContent(
      type: LegalContentType.fromString(legalContentType),
      content: content,
      updatedAt: parsedDate,
      sourceLocale: sourceLocale,
      displayedLocale: displayedLocale,
      isTranslated: isTranslated,
      translationStatus: translationStatus,
    );
  }
}

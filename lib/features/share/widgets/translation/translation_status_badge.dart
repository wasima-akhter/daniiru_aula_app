import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../utils/app_strings/app_strings.dart';
import '../../../../utils/extension/language_extension.dart';

/// Reusable non-blocking badge for dynamic multilingual content (Announcements, Homework, Legal).
/// - PENDING: Soft amber badge with a 12x12 spinner and localized "Translating..." text.
/// - isTranslated: Soft blue badge indicating translation direction (e.g. "Translated (ES → EN)").
/// - READY / Not translated: Hidden (SizedBox.shrink).
class TranslationStatusBadge extends ConsumerWidget {
  final String translationStatus;
  final bool isTranslated;
  final String sourceLocale;
  final String displayedLocale;
  final EdgeInsetsGeometry? padding;

  const TranslationStatusBadge({
    super.key,
    required this.translationStatus,
    required this.isTranslated,
    this.sourceLocale = 'en',
    this.displayedLocale = 'en',
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = translationStatus.toUpperCase();

    // 1. PENDING: Translation is being processed in background worker
    if (status == 'PENDING') {
      return Container(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: Colors.amber.shade300, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12.w,
              height: 12.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.amber.shade800,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              ref.watchTr(AppStrings.translationStatusTranslating),
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      );
    }

    // 2. isTranslated: Server returned localized content
    if (isTranslated) {
      final from = sourceLocale.toUpperCase();
      final to = displayedLocale.toUpperCase();
      final label = ref.watchTr(AppStrings.translationStatusTranslated);

      return Container(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: Colors.blue.shade200, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.g_translate_rounded,
              size: 13.sp,
              color: Colors.blue.shade700,
            ),
            SizedBox(width: 4.w),
            Text(
              '$label ($from → $to)',
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      );
    }

    // 3. READY or normal content
    return const SizedBox.shrink();
  }
}


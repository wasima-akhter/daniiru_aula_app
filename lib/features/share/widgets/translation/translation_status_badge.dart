import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/localization/localization_meta.dart';
import '../../../../core/localization/pending_refetch_controller.dart';
import '../../../../utils/app_strings/app_strings.dart';
import '../../../../utils/extension/language_extension.dart';

/// Reusable non-blocking badge for dynamic multilingual content.
/// - PENDING / PROCESSING: Soft amber badge with spinner and localized "Translating..." text.
/// - FAILED: Soft red badge indicating translation is unavailable (still shows source text).
/// - isTranslated (when sourceLocale != displayedLocale): Soft blue badge ("Translated (ES → EN)").
/// - READY / STALE / same locale: Hidden (SizedBox.shrink).
class TranslationStatusBadge extends ConsumerWidget {
  final String translationStatus;
  final bool isTranslated;
  final String sourceLocale;
  final String displayedLocale;
  final LocalizationMeta? meta;
  final EdgeInsetsGeometry? padding;

  const TranslationStatusBadge({
    super.key,
    this.translationStatus = 'READY',
    this.isTranslated = false,
    this.sourceLocale = 'en',
    this.displayedLocale = 'en',
    this.meta,
    this.padding,
  });

  const TranslationStatusBadge.fromMeta(
    this.meta, {
    super.key,
    this.padding,
  })  : translationStatus = 'READY',
        isTranslated = false,
        sourceLocale = 'en',
        displayedLocale = 'en';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveMeta = meta ??
        LocalizationMeta(
          sourceLocale: sourceLocale.toLowerCase(),
          displayedLocale: displayedLocale.toLowerCase(),
          isTranslated: isTranslated,
          translationStatus: translationStatus.toUpperCase(),
        );

    if (meta == null &&
        translationStatus == 'READY' &&
        !isTranslated) {
      return const SizedBox.shrink();
    }

    // 1. PENDING / PROCESSING: Translation is being processed in background worker
    // If polling timed out, fall back to a calm static "Original" chip instead
    // of an infinite spinner.
    if (effectiveMeta.isPending) {
      if (TranslationTimeoutScope.isTimedOutOf(context)) {
        final origLabel = ref.watchTr(AppStrings.translationStatusOriginal);
        final src = effectiveMeta.sourceLocale.toUpperCase();
        return Container(
          padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.translate_rounded,
                size: 13.sp,
                color: Colors.grey.shade700,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  '$origLabel ($src)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      }

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
            Flexible(
              child: Text(
                ref.watchTr(AppStrings.translationStatusTranslating),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. FAILED: Worker failed to translate; API returns source text
    if (effectiveMeta.isFailed) {
      return Container(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: Colors.red.shade200, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              size: 13.sp,
              color: Colors.red.shade700,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                ref.watchTr(AppStrings.translationStatusFailed),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. isTranslated (READY / STALE with different source & displayed locales)
    if (effectiveMeta.isTranslated &&
        effectiveMeta.sourceLocale.toLowerCase() !=
            effectiveMeta.displayedLocale.toLowerCase()) {
      final from = effectiveMeta.sourceLocale.toUpperCase();
      final to = effectiveMeta.displayedLocale.toUpperCase();
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
            Flexible(
              child: Text(
                '$label ($from → $to)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 4. READY / same-locale content
    return const SizedBox.shrink();
  }
}

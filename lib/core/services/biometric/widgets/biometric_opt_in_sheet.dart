import 'package:aula360/features/share/export/screen_export.dart';
import 'package:aula360/core/storage/storage_provider.dart';
import '../biometric_provider.dart';

class BiometricOptInSheet extends ConsumerWidget {
  const BiometricOptInSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BiometricOptInSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watchTr;
    final biometricState = ref.watch(biometricControllerProvider);
    final biometricController = ref.read(biometricControllerProvider.notifier);

    final title = tr(AppStrings.settingsBiometricOptInTitle);
    final description = tr(AppStrings.settingsBiometricOptInDesc);
    final enableText = tr(AppStrings.settingsBiometricOptInEnable);
    final skipText = tr(AppStrings.settingsBiometricOptInLater);

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 24.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              size: 40.sp,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TxtStyle.titleLarge(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 28.h),
          SizedBox(
            width: double.infinity,
            child: AulaPrimaryButton(
              text: enableText,
              isLoading: biometricState.isLoading,
              onTap: () async {
                final reason = tr(AppStrings.settingsBiometricAuthReason);
                final success = await biometricController.toggleBiometric(
                  true,
                  verificationReason: reason,
                );
                if (context.mounted) {
                  Navigator.of(context).pop(success);
                }
              },
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.setShownBiometricOptIn(true);
              if (context.mounted) {
                Navigator.of(context).pop(false);
              }
            },
            child: Text(
              skipText,
              style: TxtStyle.bodyMedium(
                color: AppColors.subtitleTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

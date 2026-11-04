import '../../../../core/storage/storage_provider.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/nav/user_role/user_role_provider.dart';
import '../../../../features/parent_all/presentation/controllers/parent_settings_controller.dart';
import '../../../../features/share/export/screen_export.dart';
import '../../../../features/teacher_all/settings/presentation/controllers/teacher_settings_controller.dart';
import '../../../../utils/enum/app_enum.dart';
import '../push_notification_service.dart';

/// A modern, contextual "Soft In-App Primer" bottom sheet.
///
/// Prepares the user before prompting the native OS notification dialog.
/// If the user agrees, it enables push notifications across the app:
/// requests OS permission, registers FCM token with the backend session,
/// saves notification preferences, and updates Settings state.
/// If the user dismisses ("Maybe Later"), the native OS dialog is PRESERVED
/// for future contextual opportunities.
class NotificationPrimerSheet extends ConsumerStatefulWidget {
  final BuildContext? parentContext;

  const NotificationPrimerSheet({super.key, this.parentContext});

  /// Displays the soft primer bottom sheet.
  /// Returns `true` if the user consented to enable notifications, `false` otherwise.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationPrimerSheet(parentContext: context),
    );
    return result ?? false;
  }

  /// Checks if the soft primer is appropriate to show and displays it.
  /// Automatically handles triggering permissions or recording dismissal.
  static Future<bool> showIfAppropriate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final pushService = ref.read(pushNotificationServiceProvider);
    final shouldShow = await pushService.shouldShowSoftPrimer();
    if (!shouldShow || !context.mounted) return false;

    final accepted = await show(context);
    if (!context.mounted) return accepted;

    if (!accepted) {
      await pushService.dismissSoftPrimer();
      return false;
    }
    return true;
  }

  /// Enables push notifications with the complete flow matching the Settings toggle:
  /// - Requests system permissions
  /// - Updates backend notification preferences (push: true)
  /// - Retrieves and persists the FCM token
  /// - Syncs the FCM token with the active user session on the backend
  /// - Updates the active role's settings controller state
  /// - Displays feedback (success snackbar or permission denied dialog)
  static Future<bool> enablePushNotifications(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final authUser = ref.read(authControllerProvider).user;
    final role =
        ref.read(userRoleProvider) ??
        authUser?.role ??
        ref.read(authControllerProvider).role ??
        UserRole.parent;

    final TogglePushResult result;
    if (role == UserRole.teacher) {
      result = await ref
          .read(teacherSettingsControllerProvider.notifier)
          .togglePush(true);
    } else {
      result = await ref
          .read(parentSettingsControllerProvider.notifier)
          .togglePush(true);
    }

    await ref
        .read(storageServiceProvider)
        .setNotificationPrimerDismissed(dismissed: true);

    if (!context.mounted) {
      return result == TogglePushResult.enabled;
    }

    final tr = ref.readTr;

    if (result == TogglePushResult.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(AppStrings.settingsPushEnabled),
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } else if (result == TogglePushResult.permissionDenied) {
      showPermissionDeniedDialog(context, ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(AppStrings.permissionDeniedNotice)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    return false;
  }

  /// Displays an alert directing the user to device settings if permissions were denied.
  static void showPermissionDeniedDialog(BuildContext context, WidgetRef ref) {
    final tr = ref.readTr;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: AppColors.primaryColor,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                tr(AppStrings.notificationSettingsDeniedTitle),
                style: TextStyle(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          tr(AppStrings.notificationSettingsDeniedBody),
          style: TextStyle(
            fontSize: 13.5.sp,
            color: AppColors.subtitleTextColor,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              tr(AppStrings.cancel),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(pushNotificationServiceProvider)
                  .openDeviceSettings();
            },
            child: Text(tr(AppStrings.openSettings)),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<NotificationPrimerSheet> createState() =>
      _NotificationPrimerSheetState();
}

class _NotificationPrimerSheetState
    extends ConsumerState<NotificationPrimerSheet> {
  bool _isEnabling = false;

  Future<void> _handleEnable() async {
    if (_isEnabling) return;
    setState(() => _isEnabling = true);

    final parentCtx = widget.parentContext ?? Navigator.of(context).context;
    Navigator.of(context).pop(true);

    if (parentCtx.mounted) {
      await NotificationPrimerSheet.enablePushNotifications(parentCtx, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(100.r),
              ),
            ),
            SizedBox(height: 24.h),

            // Notification Bell Graphic with soft glow
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primaryColor,
                  size: 38.sp,
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Title
            Text(
              ref.watchTr(AppStrings.notificationPrimerTitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.darkTextColor,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 10.h),

            // Subtitle
            Text(
              ref.watchTr(AppStrings.notificationPrimerSubtitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5.sp,
                color: AppColors.subtitleTextColor,
                height: 1.45,
              ),
            ),
            SizedBox(height: 24.h),

            // Benefits List
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    icon: Icons.access_time_filled_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    text: ref.watchTr(AppStrings.notificationPrimerBenefit1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
                  _buildBenefitRow(
                    icon: Icons.auto_graph_rounded,
                    iconColor: const Color(0xFF10B981),
                    text: ref.watchTr(AppStrings.notificationPrimerBenefit2),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
                  _buildBenefitRow(
                    icon: Icons.campaign_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    text: ref.watchTr(AppStrings.notificationPrimerBenefit3),
                  ),
                ],
              ),
            ),
            SizedBox(height: 26.h),

            // Enable Notifications Primary CTA
            CustomButton(
              isLoading: _isEnabling,
              onTap: _isEnabling ? null : _handleEnable,
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              text: ref.watchTr(AppStrings.notificationPrimerEnableBtn),
            ),

            SizedBox(height: 10.h),

            // Maybe Later Dismissive Action
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isEnabling
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.subtitleTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  ref.watchTr(AppStrings.notificationPrimerLaterBtn),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18.sp, color: iconColor),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

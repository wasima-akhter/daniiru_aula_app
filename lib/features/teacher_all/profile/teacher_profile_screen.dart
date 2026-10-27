import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/services/notification/push_notification_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../chat/presentation/controllers/chat_controller.dart';
import '../../parent_all/helper/parent_widgets.dart';
import '../../share/component/logout_btn.dart';
import '../../share/export/screen_export.dart';
import 'presentation/controllers/teacher_profile_controller.dart';

/// ===============================================================
/// PROFILE SCREEN
/// ===============================================================

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherProfileControllerProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: simpleAppBar(
        context,
        ref.watchTr(AppStrings.childProfile),
        showBackButton: false,
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              tooltip: 'Test Push & FCM Diagnostics',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.notifications_active),
              onPressed: () async {
                final pushService = ref.read(pushNotificationServiceProvider);
                final hasPerm = await pushService.isPermissionGranted();
                final token = await pushService.getCachedOrFetchToken();

                String syncStatus = 'Pending...';
                String profileStatus = 'Pending...';

                try {
                  if (token != null && token.isNotEmpty) {
                    await ref
                        .read(checkSessionUseCaseProvider)
                        .call(fcmToken: token);
                    syncStatus =
                        'Token synced with backend session (POST /api/v1/auth/check)';
                  } else {
                    syncStatus = 'Token is null or empty';
                  }
                } catch (e) {
                  syncStatus = 'Sync error: $e';
                }

                try {
                  await ref
                      .read(teacherProfileControllerProvider.notifier)
                      .loadProfile(force: true);
                  profileStatus =
                      'Profile loaded (GET /api/v1/profile/teacher)';
                } catch (e) {
                  profileStatus = 'Profile error: $e';
                }

                if (!context.mounted) return;
                _showPushDiagnosticsSheet(
                  context,
                  ref,
                  hasPermission: hasPerm,
                  token: token ?? '',
                  syncStatus: syncStatus,
                  profileStatus: profileStatus,
                );
              },
            )
          : null,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 30.h),
                child: Column(
                  children: [
                    _profileCard(ref, profile),
                    SizedBox(height: 20.h),
                    _sectionLabel(
                      ref.watchTr(AppStrings.academyNavigationTitle),
                    ),
                    SizedBox(height: 8.h),
                    _navigationCard(context, ref),
                    SizedBox(height: 18.h),
                    const LogoutBtn(),
                    SizedBox(height: 22.h),
                    Text(
                      ref.watchTr(AppStrings.teacherPortalBadge),
                      textAlign: TextAlign.center,
                      style: TxtStyle.titleLarge(
                        color: AppColors.subtitleTextColor,
                        fontSize: 15.sp,
                      ),
                    ),
                    // if (hasId) ...[
                    //   SizedBox(height: 4.h),
                    //   Text(
                    //     idText,
                    //     style: TxtStyle.titleLarge(
                    //       color: AppColors.hintTextColor,
                    //       fontSize: 14.5.sp,
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
    );
  }

  // ===============================================================
  // PROFILE CARD
  // ===============================================================

  Widget _profileCard(WidgetRef ref, profile) {
    final badgeText = ref.watchTr(AppStrings.verified);
    // hasId
    //     ? '${ref.watchTr(AppStrings.teacherId)}: ${teacherId.startsWith('#') ? teacherId : '#$teacherId'}'
    //     : ref.watchTr(AppStrings.teacherId);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(15.w, 18.h, 15.w, 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 76.w,
                height: 76.w,
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blueSoft, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    profile.profileImagePath ??
                        'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=500',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return Container(
                        color: AppColors.softBackground,
                        child: Icon(
                          Icons.person,
                          size: 36.sp,
                          color: AppColors.subtitleTextColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 19.w,
                  height: 19.w,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreenColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 21.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            profile.department,
            textAlign: TextAlign.center,
            style: TxtStyle.titleLarge(
              color: AppColors.subtitleTextColor,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.primaryDark,
                  size: 14.sp,
                ),
                SizedBox(width: 5.w),
                Text(
                  badgeText,
                  style: TxtStyle.titleLarge(
                    color: AppColors.primaryDark,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Divider(height: 1, color: AppColors.backgroundsLinesColor),
          SizedBox(height: 12.h),
          _contactRow(Icons.mail_outline, profile.email),
          SizedBox(height: 7.h),
          _contactRow(Icons.phone_outlined, profile.phone),
          SizedBox(height: 7.h),
          _contactRow(Icons.location_on_outlined, profile.office),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.primaryDark),
        SizedBox(width: 7.w),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TxtStyle.titleLarge(
              color: AppColors.subtitleTextColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // NAVIGATION
  // ===============================================================

  Widget _navigationCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _navigationItem(
            icon: Icons.person_outline,
            title: ref.watchTr(AppStrings.editProfileTitle),
            subtitle: ref.watchTr(AppStrings.personalContactInfoSubtitle),
            onTap: () => context.push(RoutePath.teacherEditProfile),
          ),
          _divider(),
          _navigationItem(
            icon: Icons.chat_bubble_outline,
            title: ref.watchTr(AppStrings.communicationTitle),
            subtitle: ref.watchTr(AppStrings.academyAnnouncementsSubtitle),
            onTap: () => _openCommunication(context, ref),
          ),
          _divider(),
          _navigationItem(
            icon: Icons.settings_outlined,
            title: ref.watchTr(AppStrings.settingsTitle),
            subtitle: ref.watchTr(AppStrings.settingsNavSubtitle),
            onTap: () {
              context.push(RoutePath.teacherSettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _navigationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 17.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TxtStyle.titleLarge(
                      color: AppColors.text,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TxtStyle.bodyMedium(
                      color: AppColors.subtitleTextColor,
                      fontSize: 14.5.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.subtitleTextColor,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: AppColors.backgroundsLinesColor);
  }

  void _openCommunication(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 5.h, 18.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bottomAction(
                  Icons.chat_bubble_outline,
                  ref.watchTr(AppStrings.chatWithAdmin),
                  ref.watchTr(AppStrings.communicationSubtitle),
                  () async {
                    Navigator.pop(bottomSheetContext);
                    final conv = await ref
                        .read(chatControllerProvider.notifier)
                        .startAdminConversation();
                    if (context.mounted) {
                      final activeConv =
                          conv ??
                          ref.read(chatControllerProvider).selectedConversation;
                      context.push(RoutePath.chatInbox, extra: activeConv);
                    }
                  },
                ),
                _bottomAction(
                  Icons.campaign_outlined,
                  ref.watchTr(AppStrings.announcementsTitle),
                  ref.watchTr(AppStrings.announcementsSubtitle),
                  () {
                    Navigator.pop(bottomSheetContext);
                    context.push(RoutePath.teacherAnnouncements);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(
        title,
        style: TxtStyle.titleLarge(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TxtStyle.bodyMedium(
          fontSize: 14.sp,
          color: AppColors.subtitleTextColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(AppRouter.navigatorKey.currentContext!).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TxtStyle.bodyLarge(
          color: AppColors.subtitleTextColor,
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
    );
  }

  void _showPushDiagnosticsSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool hasPermission,
    required String token,
    required String syncStatus,
    required String profileStatus,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'FCM Push Test & Diagnostics',
                            style: TxtStyle.titleLarge(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Divider(height: 1, color: AppColors.backgroundsLinesColor),
                    SizedBox(height: 14.h),

                    // 1. Permission Status
                    Row(
                      children: [
                        Icon(
                          hasPermission
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color: hasPermission
                              ? AppColors.emeraldGreenColor
                              : AppColors.orangeColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Notification Permission:',
                          style: TxtStyle.titleLarge(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: hasPermission
                                ? const Color(0xFFE5FAF2)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            hasPermission ? 'GRANTED' : 'DENIED / DISABLED',
                            style: TextStyle(
                              color: hasPermission
                                  ? AppColors.emeraldGreenColor
                                  : AppColors.orangeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!hasPermission) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'On Android 13+, push notifications are blocked by the OS until permission is granted.',
                        style: TxtStyle.bodyMedium(
                          color: AppColors.error,
                          fontSize: 12.5.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final push = ref.read(
                            pushNotificationServiceProvider,
                          );
                          final res = await push.requestPermissions();
                          final granted =
                              res?.authorizationStatus ==
                              AuthorizationStatus.authorized;
                          setModalState(() {
                            hasPermission = granted;
                          });
                        },
                        icon: const Icon(Icons.security, size: 16),
                        label: const Text('Request OS Permission Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 38.h),
                        ),
                      ),
                    ],

                    SizedBox(height: 16.h),
                    Divider(height: 1, color: AppColors.backgroundsLinesColor),
                    SizedBox(height: 14.h),

                    // 2. FCM Device Token
                    Text(
                      'Device FCM Token:',
                      style: TxtStyle.titleLarge(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3F8),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SelectableText(
                        token.isNotEmpty ? token : 'No token acquired',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5.sp,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    OutlinedButton.icon(
                      onPressed: token.isNotEmpty
                          ? () {
                              Clipboard.setData(ClipboardData(text: token));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'FCM Token copied to clipboard!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Token to Clipboard'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 38.h),
                      ),
                    ),

                    SizedBox(height: 16.h),
                    Divider(height: 1, color: AppColors.backgroundsLinesColor),
                    SizedBox(height: 14.h),

                    // 3. Backend Sync & Trigger Status
                    Text(
                      'Backend Status:',
                      style: TxtStyle.titleLarge(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    _statusRow(Icons.sync, 'Token Session Sync:', syncStatus),
                    SizedBox(height: 6.h),
                    _statusRow(Icons.person, 'Profile Trigger:', profileStatus),

                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FF),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                                size: 18.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'How to Test Real Push:',
                                style: TxtStyle.titleLarge(
                                  color: AppColors.primaryDark,
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '1. Copy the FCM token above.\n'
                            '2. Minimize the app (press Home button).\n'
                            '3. Have your backend send the push to this token, or test directly in Firebase Console > Messaging > Send Test Message.',
                            style: TxtStyle.bodyMedium(
                              fontSize: 12.5.sp,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusRow(IconData icon, String label, String value) {
    final isOk =
        !value.toLowerCase().contains('error') &&
        !value.toLowerCase().contains('null');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isOk ? Icons.check_circle_outline : Icons.error_outline,
          color: isOk ? AppColors.emeraldGreenColor : AppColors.error,
          size: 16.sp,
        ),
        SizedBox(width: 6.w),
        Text(
          '$label ',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: isOk ? AppColors.text : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

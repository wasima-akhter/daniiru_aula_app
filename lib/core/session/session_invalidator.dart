import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Parent providers
import '../../features/parent_all/data/repositories/parent_repository_impl.dart';
import '../../features/parent_all/presentation/controllers/parent_announcements_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_attendance_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_children_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_home_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_homework_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_notifications_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_payment_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_profile_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_progress_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_reports_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_schedule_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_settings_controller.dart';
import '../../features/parent_all/presentation/controllers/parent_teachers_controller.dart';

// Teacher providers
import '../../features/teacher_all/announcements/presentation/controllers/teacher_announcements_controller.dart';
import '../../features/teacher_all/attendance/presentation/controllers/teacher_attendance_controller.dart';
import '../../features/teacher_all/attendance/presentation/providers/teacher_attendance_providers.dart';
import '../../features/teacher_all/classes/presentation/controllers/teacher_classes_controller.dart';
import '../../features/teacher_all/classes/presentation/providers/teacher_classes_providers.dart';
import '../../features/teacher_all/data/repositories/teacher_repository_impl.dart';
import '../../features/teacher_all/home/presentation/controllers/teacher_home_controller.dart';
import '../../features/teacher_all/homework/presentation/controllers/teacher_homework_controller.dart';
import '../../features/teacher_all/homework/presentation/providers/teacher_homework_providers.dart';
import '../../features/teacher_all/presentation/providers/teacher_api_providers.dart';
import '../../features/teacher_all/profile/presentation/controllers/teacher_profile_controller.dart';
import '../../features/teacher_all/reports/presentation/controllers/teacher_reports_controller.dart';
import '../../features/teacher_all/reports/presentation/providers/teacher_reports_providers.dart';
import '../../features/teacher_all/settings/presentation/controllers/teacher_settings_controller.dart';
import '../../features/teacher_all/students/presentation/controllers/teacher_student_detail_controller.dart';
import '../../features/teacher_all/students/presentation/controllers/teacher_students_controller.dart';
import '../../features/teacher_all/students/presentation/providers/teacher_students_providers.dart';

// Shared providers
import '../../features/chat/presentation/controllers/chat_controller.dart';
import '../../features/nav/presentation/screens/navigation_provider.dart';

/// Centralized session state cleanup.
/// Invalidates all user-scoped feature controllers, cached repositories,
/// and resets navigation state to ensure no stale data persists across
/// different user logins of the same or different role.
void clearUserSessionState(Ref ref) {
  debugPrint(
    'clearUserSessionState: Invalidating all user-scoped providers & repositories...',
  );

  // Reset navigation to tab 0
  try {
    ref.invalidate(navigationProvider);
  } catch (e) {
    debugPrint('Error invalidating navigationProvider: $e');
  }

  // Parent Feature Controllers & Providers
  try {
    ref.invalidate(parentHomeControllerProvider);
    ref.invalidate(parentProfileControllerProvider);
    ref.invalidate(parentChildrenControllerProvider);
    ref.invalidate(parentAttendanceControllerProvider);
    ref.invalidate(parentHomeworkControllerProvider);
    ref.invalidate(parentPaymentControllerProvider);
    ref.invalidate(parentReportsControllerProvider);
    ref.invalidate(parentScheduleControllerProvider);
    ref.invalidate(parentSettingsControllerProvider);
    ref.invalidate(parentNotificationsControllerProvider);
    ref.invalidate(parentAnnouncementsControllerProvider);
    ref.invalidate(parentTeachersControllerProvider);
    ref.invalidate(parentProgressControllerProvider);
    ref.invalidate(parentRepositoryProvider);
  } catch (e) {
    debugPrint('Error invalidating parent providers: $e');
  }

  // Teacher Feature Controllers & Providers
  try {
    ref.invalidate(teacherHomeControllerProvider);
    ref.invalidate(teacherProfileControllerProvider);
    ref.invalidate(teacherClassesControllerProvider);
    ref.invalidate(teacherStudentsControllerProvider);
    ref.invalidate(teacherStudentDetailControllerProvider);
    ref.invalidate(teacherReportsControllerProvider);
    ref.invalidate(teacherReportFormControllerProvider);
    ref.invalidate(teacherHomeworkControllerProvider);
    ref.invalidate(teacherHomeworkListControllerProvider);
    ref.invalidate(teacherAttendanceControllerProvider);
    ref.invalidate(teacherSettingsControllerProvider);
    ref.invalidate(teacherAnnouncementsControllerProvider);
    ref.invalidate(teacherActionControllerProvider);
    ref.invalidate(teacherRepositoryProvider);
    ref.invalidate(teacherClassesRepositoryProvider);
    ref.invalidate(teacherStudentsRepositoryProvider);
    ref.invalidate(teacherReportsRepositoryProvider);
    ref.invalidate(teacherHomeworkRepositoryProvider);
    ref.invalidate(teacherAttendanceRepositoryProvider);
  } catch (e) {
    debugPrint('Error invalidating teacher providers: $e');
  }

  // Shared Providers
  try {
    ref.invalidate(chatControllerProvider);
  } catch (e) {
    debugPrint('Error invalidating chatControllerProvider: $e');
  }
}

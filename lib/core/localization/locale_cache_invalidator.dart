import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/parent_all/data/repositories/parent_repository_impl.dart';
import '../../features/parent_all/presentation/controllers/parent_reports_controller.dart';
import '../../features/teacher_all/classes/presentation/providers/teacher_classes_providers.dart';
import '../../features/teacher_all/homework/presentation/providers/teacher_homework_providers.dart';
import '../../features/teacher_all/reports/presentation/providers/teacher_reports_providers.dart';
import '../network/socket_service.dart';

/// Clears in-memory repository caches, reconnects Socket.IO with the updated
/// locale headers, and invalidates cached detail FutureProviders so active UI
/// surfaces refetch translated content immediately after a language switch.
Future<void> onAppLanguageChanged(WidgetRef ref) async {
  try {
    final parentRepo = ref.read(parentRepositoryProvider);
    if (parentRepo is ParentRepositoryImpl) {
      parentRepo.clearCache();
    }
  } catch (_) {}

  try {
    ref.invalidate(childReportDetailProvider);
    ref.invalidate(teacherSessionDetailProvider);
    ref.invalidate(teacherReportDetailProvider);
    ref.invalidate(teacherHomeworkListProvider);
  } catch (_) {}

  try {
    await ref.read(socketServiceProvider).reconnectForLocaleChange();
  } catch (_) {}
}

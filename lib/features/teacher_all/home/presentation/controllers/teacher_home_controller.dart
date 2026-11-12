import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aula360/features/teacher_all/classes/domain/repositories/teacher_classes_repository.dart';
import 'package:aula360/features/teacher_all/classes/presentation/providers/teacher_classes_providers.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int parseTimeToMinutes(String timeStr) {
  try {
    final clean = timeStr.trim();
    if (clean.isEmpty) return 0;
    if (clean.contains('T')) {
      final dt = DateTime.tryParse(clean);
      if (dt != null) return dt.hour * 60 + dt.minute;
    }
    final isPm = clean.toUpperCase().contains('PM');
    final isAm = clean.toUpperCase().contains('AM');
    final timeOnly = clean.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = timeOnly.split(':');
    if (parts.isNotEmpty) {
      int hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return hour * 60 + minute;
    }
  } catch (_) {}
  return 0;
}

class TeacherHomeState {
  final List<HomeScheduleItem> schedule;
  final bool isLoading;
  final String? error;

  const TeacherHomeState({
    this.schedule = const [],
    this.isLoading = false,
    this.error,
  });

  /// The next timed session of status ONGOING or SCHEDULED.
  /// Priority:
  /// 1. An active [ONGOING] session if one exists.
  /// 2. The next upcoming [SCHEDULED] session chronologically.
  /// 3. Returns null if all sessions are COMPLETED or CANCELLED, or if none exist.
  HomeScheduleItem? get nextSession {
    if (schedule.isEmpty) return null;

    // 1. Any currently active ONGOING session
    for (final item in schedule) {
      if (item.rawStatus.toUpperCase() == 'ONGOING') {
        return item;
      }
    }

    // 2. Filter for SCHEDULED sessions
    final scheduledSessions = schedule
        .where((s) => s.rawStatus.toUpperCase() == 'SCHEDULED')
        .toList();

    if (scheduledSessions.isEmpty) return null;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Find the first upcoming scheduled session whose end time hasn't passed
    for (final s in scheduledSessions) {
      int endMinutes = parseTimeToMinutes(s.endTime);
      if (endMinutes == 0) {
        endMinutes = parseTimeToMinutes(s.startTime);
      }
      if (endMinutes > currentMinutes) {
        return s;
      }
    }

    // Fallback: if all scheduled sessions ended according to clock but status is still SCHEDULED,
    // return the first scheduled session
    return scheduledSessions.first;
  }

  TeacherHomeState copyWith({
    List<HomeScheduleItem>? schedule,
    bool? isLoading,
    String? error,
  }) {
    return TeacherHomeState(
      schedule: schedule ?? this.schedule,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final teacherHomeControllerProvider =
    NotifierProvider<TeacherHomeController, TeacherHomeState>(
      TeacherHomeController.new,
    );

class TeacherHomeController extends Notifier<TeacherHomeState> {
  TeacherClassesRepository get _classesRepository =>
      ref.read(teacherClassesRepositoryProvider);

  @override
  TeacherHomeState build() {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        if (next.user != null) {
          state = const TeacherHomeState(isLoading: true);
          Future.microtask(() => loadHomeData());
        } else {
          state = const TeacherHomeState();
        }
      }
    });

    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        Future.microtask(() => loadHomeData());
      }
    });

    Future.microtask(() => loadHomeData());
    return const TeacherHomeState(isLoading: true);
  }

  Future<void> loadHomeData() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _classesRepository.getSessions(
        date: DateTime.now(),
      );
      if (!ref.mounted) return;
      if (sessions.isNotEmpty) {
        final sortedSessions = List.of(sessions)
          ..sort((a, b) {
            final aMin = parseTimeToMinutes(a.startTime);
            final bMin = parseTimeToMinutes(b.startTime);
            return aMin.compareTo(bMin);
          });

        final items = sortedSessions.map((s) {
          final isOngoing = s.status.toUpperCase() == 'ONGOING';
          return HomeScheduleItem(
            id: s.id,
            scheduleId: s.scheduleId,
            startTime: s.startTime,
            endTime: s.endTime,
            title: s.subjectName,
            subtitle: s.cohortName,
            room: s.classroomRoomNumber,
            group: s.cohortName,
            students: 24,
            type: isOngoing ? HomeClassType.next : HomeClassType.scheduled,
            rawStatus: s.status,
          );
        }).toList();
        state = state.copyWith(schedule: items, isLoading: false, error: null);
      } else {
        state = state.copyWith(
          schedule: const [],
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        schedule: const [],
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

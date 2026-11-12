import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import '../../data/dtos/child_schedule_dto.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';
import 'parent_children_controller.dart';

class ParentScheduleState {
  final List<ClassModel> classes;
  final List<ChildScheduleSessionDto> rawSessions;
  final int selectedDayIndex;
  final int selectedChildIndex;
  final DateTime selectedDate;
  final DateTime anchorDate;
  final bool isLoading;
  final String? error;

  ParentScheduleState({
    this.classes = const [],
    this.rawSessions = const [],
    this.selectedDayIndex = 2,
    this.selectedChildIndex = 0,
    DateTime? selectedDate,
    DateTime? anchorDate,
    this.isLoading = false,
    this.error,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        anchorDate = anchorDate ?? (selectedDate ?? DateTime.now());

  ParentScheduleState copyWith({
    List<ClassModel>? classes,
    List<ChildScheduleSessionDto>? rawSessions,
    int? selectedDayIndex,
    int? selectedChildIndex,
    DateTime? selectedDate,
    DateTime? anchorDate,
    bool? isLoading,
    String? error,
  }) {
    return ParentScheduleState(
      classes: classes ?? this.classes,
      rawSessions: rawSessions ?? this.rawSessions,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      selectedChildIndex: selectedChildIndex ?? this.selectedChildIndex,
      selectedDate: selectedDate ?? this.selectedDate,
      anchorDate: anchorDate ?? this.anchorDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final parentScheduleControllerProvider =
    NotifierProvider<ParentScheduleController, ParentScheduleState>(
      ParentScheduleController.new,
    );

class ParentScheduleController extends Notifier<ParentScheduleState> {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  ParentScheduleState build() {
    ref.listen(parentChildrenControllerProvider, (previous, next) {
      if (previous?.selectedChild?.id != next.selectedChild?.id ||
          ((previous?.children.isEmpty ?? true) && next.children.isNotEmpty)) {
        final newIndex = next.children.isNotEmpty && next.selectedChild != null
            ? next.children.indexWhere((c) => c.id == next.selectedChild!.id)
            : 0;
        final effectiveIndex = newIndex != -1 ? newIndex : 0;
        if (state.selectedChildIndex != effectiveIndex || state.rawSessions.isEmpty) {
          state = state.copyWith(selectedChildIndex: effectiveIndex);
          loadSchedule(
            state.selectedDayIndex,
            childId: next.selectedChild?.id,
            date: state.selectedDate,
            anchor: state.anchorDate,
          );
        }
      }
    });

    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        Future.microtask(
          () => loadSchedule(
            state.selectedDayIndex,
            date: state.selectedDate,
            anchor: state.anchorDate,
          ),
        );
      }
    });

    final activeChild = ref.read(parentChildrenControllerProvider).selectedChild;
    final children = ref.read(parentChildrenControllerProvider).children;
    final initialIndex = (activeChild != null && children.isNotEmpty)
        ? children.indexWhere((c) => c.id == activeChild.id)
        : 0;
    final effectiveInitialIndex = initialIndex != -1 ? initialIndex : 0;
    final now = DateTime.now();

    Future.microtask(() => loadSchedule(2, childId: activeChild?.id, date: now, anchor: now));
    return ParentScheduleState(
      isLoading: true,
      selectedDayIndex: 2,
      selectedChildIndex: effectiveInitialIndex,
      selectedDate: now,
      anchorDate: now,
    );
  }

  Future<void> loadSchedule(
    int dayIndex, {
    String? childId,
    DateTime? date,
    DateTime? anchor,
  }) async {
    final effectiveDate = date ?? state.selectedDate;
    final effectiveAnchor = anchor ?? date ?? state.anchorDate;
    state = state.copyWith(
      isLoading: true,
      selectedDayIndex: dayIndex,
      selectedDate: effectiveDate,
      anchorDate: effectiveAnchor,
      error: null,
    );
    try {
      final childrenState = ref.read(parentChildrenControllerProvider);
      final children = childrenState.children;
      final effectiveChildId = childId ??
          (children.isNotEmpty && state.selectedChildIndex < children.length
              ? children[state.selectedChildIndex].id
              : childrenState.selectedChild?.id);

      if (effectiveChildId != null && effectiveChildId.isNotEmpty) {
        final now = DateTime.now();
        final isCurrentMonth =
            effectiveDate.year == now.year && effectiveDate.month == now.month;
        final fromDate = isCurrentMonth
            ? null
            : DateTime.utc(effectiveDate.year, effectiveDate.month, 1);
        final toDate = isCurrentMonth
            ? null
            : DateTime.utc(effectiveDate.year, effectiveDate.month + 1, 0, 23, 59, 59);

        final sessions = await _repository.getChildSchedule(
          effectiveChildId,
          fromDate: fromDate,
          toDate: toDate,
        );
        state = state.copyWith(
          rawSessions: sessions,
          classes: sessions.map((s) => s.toClassModel()).toList(),
          selectedDayIndex: dayIndex,
          selectedDate: effectiveDate,
          anchorDate: effectiveAnchor,
          isLoading: false,
          error: null,
        );
        return;
      }

      state = state.copyWith(
        rawSessions: const [],
        classes: const [],
        selectedDayIndex: dayIndex,
        selectedDate: effectiveDate,
        anchorDate: effectiveAnchor,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadSchedule(
      state.selectedDayIndex,
      date: state.selectedDate,
      anchor: state.anchorDate,
    );
  }

  void selectDay(int dayIndex, [DateTime? date]) {
    final targetDate = date ?? state.anchorDate.add(Duration(days: dayIndex - 2));
    loadSchedule(dayIndex, date: targetDate, anchor: state.anchorDate);
  }

  void selectCustomDate(DateTime date) {
    loadSchedule(2, date: date, anchor: date);
  }

  void resetToToday() {
    final now = DateTime.now();
    loadSchedule(2, date: now, anchor: now);
  }

  void selectChild(int childIndex) {
    final children = ref.read(parentChildrenControllerProvider).children;
    if (childIndex >= 0 && childIndex < children.length) {
      final child = children[childIndex];
      ref.read(parentChildrenControllerProvider.notifier).selectChild(child);
      state = state.copyWith(selectedChildIndex: childIndex);
      loadSchedule(
        state.selectedDayIndex,
        childId: child.id,
        date: state.selectedDate,
        anchor: state.anchorDate,
      );
    } else {
      state = state.copyWith(selectedChildIndex: childIndex);
      loadSchedule(
        state.selectedDayIndex,
        date: state.selectedDate,
        anchor: state.anchorDate,
      );
    }
  }
}

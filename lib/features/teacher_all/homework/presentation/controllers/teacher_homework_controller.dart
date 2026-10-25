import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';
import 'package:aula360/features/teacher_all/homework/domain/repositories/teacher_homework_repository.dart';
import 'package:aula360/features/teacher_all/homework/presentation/providers/teacher_homework_providers.dart';

class TeacherHomeworkActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const TeacherHomeworkActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  TeacherHomeworkActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return TeacherHomeworkActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

final teacherHomeworkControllerProvider =
    NotifierProvider<TeacherHomeworkController, TeacherHomeworkActionState>(
  TeacherHomeworkController.new,
);

class TeacherHomeworkController extends Notifier<TeacherHomeworkActionState> {
  TeacherHomeworkRepository get _repository => ref.read(teacherHomeworkRepositoryProvider);

  @override
  TeacherHomeworkActionState build() {
    return const TeacherHomeworkActionState();
  }

  Future<bool> createHomework({
    required String cohortId,
    required String subjectId,
    String? sessionId,
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime dueDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final payload = CreateHomeworkRequestDto(
        cohortId: cohortId,
        subjectId: subjectId,
        sessionId: sessionId,
        title: title,
        description: description,
        startDate: startDate.toIso8601String(),
        dueDate: dueDate.toIso8601String(),
      );
      await _repository.createHomework(payload);
      ref.invalidate(teacherHomeworkListControllerProvider);
      ref.invalidate(teacherHomeworkListProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Tarea creada con éxito',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> markHomeworkSubmission({
    required String homeworkId,
    required String studentId,
    required String status,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final payload = MarkHomeworkSubmissionRequestDto(
        status: status,
        note: note,
      );
      await _repository.markHomeworkSubmission(homeworkId, studentId, payload);
      ref.invalidate(teacherHomeworkListControllerProvider);
      ref.invalidate(teacherHomeworkListProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Entrega actualizada',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

class TeacherHomeworkListState {
  final List<TeacherHomeworkDto> items;
  final String? selectedCohortId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const TeacherHomeworkListState({
    this.items = const [],
    this.selectedCohortId,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  TeacherHomeworkListState copyWith({
    List<TeacherHomeworkDto>? items,
    String? selectedCohortId,
    bool clearCohort = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return TeacherHomeworkListState(
      items: items ?? this.items,
      selectedCohortId:
          clearCohort ? null : (selectedCohortId ?? this.selectedCohortId),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

final teacherHomeworkListControllerProvider = NotifierProvider<
    TeacherHomeworkListController, TeacherHomeworkListState>(
  TeacherHomeworkListController.new,
);

class TeacherHomeworkListController extends Notifier<TeacherHomeworkListState> {
  static const int _pageSize = 20;
  TeacherHomeworkRepository get _repository =>
      ref.read(teacherHomeworkRepositoryProvider);

  @override
  TeacherHomeworkListState build() {
    Future.microtask(() => loadInitial());
    return const TeacherHomeworkListState(isLoading: true);
  }

  Future<void> filterByCohort(String? cohortId) async {
    state = state.copyWith(
      selectedCohortId: cohortId,
      clearCohort: cohortId == null,
    );
    await loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMore: true,
      clearLoadMoreError: true,
    );
    try {
      final res = await _repository.getHomework(
        cohortId: state.selectedCohortId,
        page: 1,
        limit: _pageSize,
      );
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      state = state.copyWith(
        items: res.data,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMore: hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await _repository.getHomework(
        cohortId: state.selectedCohortId,
        page: nextPage,
        limit: _pageSize,
      );
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      final existingIds = state.items.map((i) => i.id).toSet();
      final newItems =
          res.data.where((i) => !existingIds.contains(i.id)).toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        currentPage: nextPage,
        hasMore: hasNext,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadInitial();
}


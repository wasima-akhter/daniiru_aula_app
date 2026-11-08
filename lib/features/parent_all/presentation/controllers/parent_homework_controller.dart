import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';
import 'parent_children_controller.dart';

class ParentHomeworkState {
  final List<HomeworkModel> homework;
  final List<StudentModel> students;
  final int selectedStudentIndex;
  final int selectedTab;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const ParentHomeworkState({
    this.homework = const [],
    this.students = const [],
    this.selectedStudentIndex = 0,
    this.selectedTab = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  List<HomeworkModel> get filteredHomework {
    if (selectedTab == 0) return homework;
    if (selectedTab == 1) {
      return homework
          .where((item) => item.status == HomeworkStatus.pending)
          .toList();
    }
    return homework
          .where((item) => item.status == HomeworkStatus.completed)
          .toList();
  }

  ParentHomeworkState copyWith({
    List<HomeworkModel>? homework,
    List<StudentModel>? students,
    int? selectedStudentIndex,
    int? selectedTab,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ParentHomeworkState(
      homework: homework ?? this.homework,
      students: students ?? this.students,
      selectedStudentIndex: selectedStudentIndex ?? this.selectedStudentIndex,
      selectedTab: selectedTab ?? this.selectedTab,
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

final parentHomeworkControllerProvider =
    NotifierProvider<ParentHomeworkController, ParentHomeworkState>(
  ParentHomeworkController.new,
);

class ParentHomeworkController extends Notifier<ParentHomeworkState> {
  static const int _pageSize = 20;
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  ParentHomeworkState build() {
    final children = ref.watch(parentChildrenControllerProvider).children;
    final students = children
        .map((c) => StudentModel(
              name: c.name,
              grade: '${c.grade} • ${c.classroom}',
              initials: c.initials,
            ))
        .toList();

    // Reactive SWR: Invalidate & refetch in background when app language changes
    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        Future.microtask(() => loadHomework(null, true));
      }
    });

    Future.microtask(() => loadHomework());
    return ParentHomeworkState(isLoading: true, students: students);
  }

  String? _getActiveChildId() {
    final children = ref.read(parentChildrenControllerProvider).children;
    if (state.selectedStudentIndex < children.length) {
      return children[state.selectedStudentIndex].id;
    }
    return ref.read(parentChildrenControllerProvider).selectedChild?.id;
  }

  Future<void> loadHomework([String? childId, bool isLanguageChange = false]) async {
    try {
      if (!isLanguageChange) {
        state = state.copyWith(
          isLoading: true,
          error: null,
          currentPage: 1,
          hasMore: true,
          clearLoadMoreError: true,
        );
      }
      final id = childId ?? _getActiveChildId();
      final res = id != null
          ? await _repository.getChildHomework(id, page: 1, limit: _pageSize)
          : await _repository.getHomeworkList(page: 1, limit: _pageSize);
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      state = state.copyWith(
        homework: res.data,
        isLoading: false,
        currentPage: 1,
        hasMore: hasNext,
      );
    } catch (e) {
      if (!isLanguageChange) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Paginated load more: strictly checks beforehand if there is more data.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.currentPage + 1;
    final id = _getActiveChildId();

    try {
      final res = id != null
          ? await _repository.getChildHomework(id, page: nextPage, limit: _pageSize)
          : await _repository.getHomeworkList(page: nextPage, limit: _pageSize);
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      final existingIds = state.homework.map((h) => h.id).toSet();
      final newItems =
          res.data.where((h) => !existingIds.contains(h.id)).toList();

      state = state.copyWith(
        homework: [...state.homework, ...newItems],
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

  Future<void> refresh() => loadHomework();

  void selectStudent(int index) {
    state = state.copyWith(selectedStudentIndex: index);
    final children = ref.read(parentChildrenControllerProvider).children;
    if (index >= 0 && index < children.length) {
      loadHomework(children[index].id);
    }
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTab: index);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/students/domain/repositories/teacher_students_repository.dart';
import 'package:aula360/features/teacher_all/students/presentation/providers/teacher_students_providers.dart';

class TeacherStudentsState {
  final List<TeacherStudent> students;
  final StudentGroupFilter selectedFilter;
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const TeacherStudentsState({
    this.students = const [],
    this.selectedFilter = StudentGroupFilter.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  List<TeacherStudent> get filteredStudents {
    return students.where((student) {
      final matchesGroup = switch (selectedFilter) {
        StudentGroupFilter.all => true,
        StudentGroupFilter.groupA => student.group == StudentGroup.groupA,
        StudentGroupFilter.groupB => student.group == StudentGroup.groupB,
      };
      final matchesSearch =
          searchQuery.isEmpty ||
          student.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          student.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
          student.room.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesGroup && matchesSearch;
    }).toList();
  }

  TeacherStudentsState copyWith({
    List<TeacherStudent>? students,
    StudentGroupFilter? selectedFilter,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return TeacherStudentsState(
      students: students ?? this.students,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }
}

final teacherStudentsControllerProvider =
    NotifierProvider<TeacherStudentsController, TeacherStudentsState>(
  TeacherStudentsController.new,
);

class TeacherStudentsController extends Notifier<TeacherStudentsState> {
  static const int _pageSize = 20;
  TeacherStudentsRepository get _repository =>
      ref.read(teacherStudentsRepositoryProvider);

  @override
  TeacherStudentsState build() {
    Future.microtask(() => loadStudents());
    return const TeacherStudentsState(isLoading: true);
  }

  Future<void> loadStudents({String? search}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMore: true,
      clearLoadMoreError: true,
    );
    try {
      final list = await _repository.getStudents(
        page: 1,
        limit: _pageSize,
        search: search,
      );
      state = state.copyWith(
        students: list,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMore: list.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Paginated load more: strictly checks beforehand if there is more data.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.currentPage + 1;

    try {
      final nextList = await _repository.getStudents(
        page: nextPage,
        limit: _pageSize,
        search: state.searchQuery.trim().isEmpty
            ? null
            : state.searchQuery.trim(),
      );

      final existingIds = state.students.map((s) => s.id).toSet();
      final newItems =
          nextList.where((s) => !existingIds.contains(s.id)).toList();
      final updated = [...state.students, ...newItems];

      state = state.copyWith(
        students: updated,
        currentPage: nextPage,
        hasMore: nextList.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadStudents(
      search:
          state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
    );
  }

  void selectFilter(StudentGroupFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

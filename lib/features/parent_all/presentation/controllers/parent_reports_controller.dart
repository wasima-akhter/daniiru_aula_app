import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import '../../data/dtos/child_report_dto.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';
import 'parent_children_controller.dart';

class ParentReportsState {
  final List<ReportModel> reports;
  final List<StudentModel> students;
  final int selectedStudentIndex;
  final int selectedCategoryIndex;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const ParentReportsState({
    this.reports = const [],
    this.students = const [],
    this.selectedStudentIndex = 0,
    this.selectedCategoryIndex = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  List<ReportModel> getFilteredReports(List<String> categories) {
    if (selectedCategoryIndex == 0 ||
        selectedCategoryIndex >= categories.length) {
      return reports;
    }
    final category = categories[selectedCategoryIndex].toLowerCase();
    return reports.where((report) {
      return report.category.toLowerCase().contains(category) ||
          category.contains(report.category.toLowerCase());
    }).toList();
  }

  Map<String, List<ReportModel>> getGroupedReports(List<String> categories) {
    final filtered = getFilteredReports(categories);
    final Map<String, List<ReportModel>> grouped = {};
    for (final report in filtered) {
      grouped.putIfAbsent(report.dateLabel, () => []);
      grouped[report.dateLabel]!.add(report);
    }
    return grouped;
  }

  ParentReportsState copyWith({
    List<ReportModel>? reports,
    List<StudentModel>? students,
    int? selectedStudentIndex,
    int? selectedCategoryIndex,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ParentReportsState(
      reports: reports ?? this.reports,
      students: students ?? this.students,
      selectedStudentIndex: selectedStudentIndex ?? this.selectedStudentIndex,
      selectedCategoryIndex:
          selectedCategoryIndex ?? this.selectedCategoryIndex,
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

final parentReportsControllerProvider =
    NotifierProvider<ParentReportsController, ParentReportsState>(
  ParentReportsController.new,
);

class ParentReportsController extends Notifier<ParentReportsState> {
  static const int _pageSize = 20;
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  ParentReportsState build() {
    final children = ref.watch(parentChildrenControllerProvider).children;
    final students = children
        .map((c) => StudentModel(
              name: c.name,
              grade: '${c.grade} • ${c.classroom}',
              initials: c.initials,
            ))
        .toList();

    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        Future.microtask(() => loadReports());
      }
    });

    Future.microtask(() => loadReports());
    return ParentReportsState(isLoading: true, students: students);
  }

  String? _getActiveChildId() {
    final children = ref.read(parentChildrenControllerProvider).children;
    if (state.selectedStudentIndex < children.length) {
      return children[state.selectedStudentIndex].id;
    }
    return ref.read(parentChildrenControllerProvider).selectedChild?.id;
  }

  Future<void> loadReports([String? childId]) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
        clearLoadMoreError: true,
      );
      final id = childId ?? _getActiveChildId();
      final res = id != null
          ? await _repository.getChildReports(id, page: 1, limit: _pageSize)
          : await _repository.getReports(page: 1, limit: _pageSize);
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      state = state.copyWith(
        reports: res.data,
        isLoading: false,
        currentPage: 1,
        hasMore: hasNext,
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
    final id = _getActiveChildId();

    try {
      final res = id != null
          ? await _repository.getChildReports(id, page: nextPage, limit: _pageSize)
          : await _repository.getReports(page: nextPage, limit: _pageSize);
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      final existingIds = state.reports.map((r) => r.id).toSet();
      final newItems =
          res.data.where((r) => !existingIds.contains(r.id)).toList();

      state = state.copyWith(
        reports: [...state.reports, ...newItems],
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

  Future<void> refresh() => loadReports();

  void selectStudent(int index) {
    state = state.copyWith(selectedStudentIndex: index);
    final children = ref.read(parentChildrenControllerProvider).children;
    if (index >= 0 && index < children.length) {
      loadReports(children[index].id);
    }
  }

  void selectCategory(int index) {
    state = state.copyWith(selectedCategoryIndex: index);
  }
}

class ChildReportDetailParams {
  final String childId;
  final String reportId;

  const ChildReportDetailParams({
    required this.childId,
    required this.reportId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildReportDetailParams &&
          runtimeType == other.runtimeType &&
          childId == other.childId &&
          reportId == other.reportId;

  @override
  int get hashCode => Object.hash(childId, reportId);
}

final childReportDetailProvider = FutureProvider.autoDispose
    .family<ChildReportDetailDto, ChildReportDetailParams>(
  (ref, params) async {
    ref.watch(languageProvider.select((v) => v.asData?.value.languageCode));
    return ref
        .watch(parentRepositoryProvider)
        .getChildReportDetail(params.childId, params.reportId);
  },
);


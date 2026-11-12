import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';
import 'parent_children_controller.dart';

class ParentAttendanceState {
  final List<AttendanceRecord> records;
  final int selectedChildIndex;
  final AttendanceStatus? filterStatus;
  final int percentage;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const ParentAttendanceState({
    this.records = const [],
    this.selectedChildIndex = 0,
    this.filterStatus,
    this.percentage = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  List<AttendanceRecord> get filteredRecords {
    if (filterStatus == null) return records;
    return records.where((r) => r.status == filterStatus).toList();
  }

  int get presentCount =>
      records.where((r) => r.status == AttendanceStatus.present).length;
  int get absentCount =>
      records.where((r) => r.status == AttendanceStatus.absent).length;
  int get lateCount =>
      records.where((r) => r.status == AttendanceStatus.late).length;

  ParentAttendanceState copyWith({
    List<AttendanceRecord>? records,
    int? selectedChildIndex,
    AttendanceStatus? filterStatus,
    int? percentage,
    bool clearFilter = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ParentAttendanceState(
      records: records ?? this.records,
      selectedChildIndex: selectedChildIndex ?? this.selectedChildIndex,
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      percentage: percentage ?? this.percentage,
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

final parentAttendanceControllerProvider =
    NotifierProvider<ParentAttendanceController, ParentAttendanceState>(
  ParentAttendanceController.new,
);

class ParentAttendanceController extends Notifier<ParentAttendanceState> {
  static const int _pageSize = 20;
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  ParentAttendanceState build() {
    final activeChildId = ref.watch(
      parentChildrenControllerProvider.select((s) => s.selectedChild?.id),
    );
    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        Future.microtask(() => loadAttendance());
      }
    });
    if (activeChildId != null && activeChildId.isNotEmpty) {
      Future.microtask(() => loadAttendance(activeChildId));
    }
    return const ParentAttendanceState(percentage: 0, isLoading: true);
  }

  String _getActiveChildId([String? childId]) {
    if (childId != null && childId.isNotEmpty) return childId;
    final children = ref.read(parentChildrenControllerProvider).children;
    if (state.selectedChildIndex < children.length) {
      return children[state.selectedChildIndex].id;
    }
    return ref.read(parentChildrenControllerProvider).selectedChild?.id ?? '';
  }

  Future<void> loadAttendance([String? childId]) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMore: true,
      clearLoadMoreError: true,
    );
    try {
      final id = _getActiveChildId(childId);
      if (id.isEmpty) {
        state = state.copyWith(isLoading: false, percentage: 0);
        return;
      }
      final (meta, records) = await _repository.getAttendanceHistory(
        id,
        page: 1,
        limit: _pageSize,
      );
      int percentage = meta?.percentage ?? 0;
      if (percentage == 0) {
        percentage = await _repository.getChildAttendancePercentage(id);
      }
      if (percentage == 0 && records.isNotEmpty) {
        final presentCount =
            records.where((r) => r.status == AttendanceStatus.present).length;
        percentage = ((presentCount / records.length) * 100).round();
      }
      final hasNext = meta != null
          ? (1 < meta.totalPages)
          : (records.length >= _pageSize);

      state = state.copyWith(
        records: records,
        percentage: percentage,
        isLoading: false,
        error: null,
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
    if (id.isEmpty) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      final (meta, nextRecords) = await _repository.getAttendanceHistory(
        id,
        page: nextPage,
        limit: _pageSize,
      );

      final existingKeys = state.records
          .map((r) => '${r.date}_${r.dayName}_${r.checkInTime}')
          .toSet();
      final newItems = nextRecords
          .where((r) => !existingKeys
              .contains('${r.date}_${r.dayName}_${r.checkInTime}'))
          .toList();

      final hasNext = meta != null
          ? (nextPage < meta.totalPages)
          : (nextRecords.length >= _pageSize);

      state = state.copyWith(
        records: [...state.records, ...newItems],
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

  Future<void> refresh() => loadAttendance();

  void selectChild(int index) {
    state = state.copyWith(selectedChildIndex: index);
    final children = ref.read(parentChildrenControllerProvider).children;
    if (index >= 0 && index < children.length) {
      loadAttendance(children[index].id);
    }
  }

  void setFilter(AttendanceStatus? status) {
    if (state.filterStatus == status) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }
}

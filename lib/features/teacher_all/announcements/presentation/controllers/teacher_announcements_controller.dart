import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../parent_all/data/dtos/announcement_dto.dart';
import '../../../data/repositories/teacher_repository_impl.dart';
import '../../../domain/repositories/teacher_repository.dart';

class TeacherAnnouncementsState {
  final List<AnnouncementDto> announcements;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const TeacherAnnouncementsState({
    this.announcements = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  TeacherAnnouncementsState copyWith({
    List<AnnouncementDto>? announcements,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return TeacherAnnouncementsState(
      announcements: announcements ?? this.announcements,
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

final teacherAnnouncementsControllerProvider =
    NotifierProvider<TeacherAnnouncementsController, TeacherAnnouncementsState>(
  TeacherAnnouncementsController.new,
);

class TeacherAnnouncementsController extends Notifier<TeacherAnnouncementsState> {
  static const int _pageSize = 10;
  TeacherRepository get _repository => ref.read(teacherRepositoryProvider);

  @override
  TeacherAnnouncementsState build() {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        if (next.user != null) {
          state = const TeacherAnnouncementsState(isLoading: true);
          Future.microtask(() => loadAnnouncements());
        } else {
          state = const TeacherAnnouncementsState();
        }
      }
    });
    Future.microtask(() => loadAnnouncements());
    return const TeacherAnnouncementsState(isLoading: true);
  }

  Future<void> loadAnnouncements({int page = 1, int limit = _pageSize}) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
        clearLoadMoreError: true,
      );
      final res = await _repository.getAnnouncements(
        page: page,
        limit: limit,
      );
      state = state.copyWith(
        announcements: res.items,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMore: res.hasMore,
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
      final res = await _repository.getAnnouncements(
        page: nextPage,
        limit: _pageSize,
      );
      final existingIds = state.announcements.map((a) => a.id).toSet();
      final newItems =
          res.items.where((a) => !existingIds.contains(a.id)).toList();
      state = state.copyWith(
        announcements: [...state.announcements, ...newItems],
        currentPage: nextPage,
        hasMore: res.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadAnnouncements();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';

class ParentNotificationsState {
  final List<ParentNotificationModel> notifications;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const ParentNotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  ParentNotificationsState copyWith({
    List<ParentNotificationModel>? notifications,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ParentNotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

final parentNotificationsControllerProvider =
    NotifierProvider<ParentNotificationsController, ParentNotificationsState>(
  ParentNotificationsController.new,
);

class ParentNotificationsController extends Notifier<ParentNotificationsState> {
  static const int _pageSize = 20;
  ParentRepository get _repository => ref.read(parentRepositoryProvider);
  bool _isFetching = false;

  @override
  ParentNotificationsState build() {
    Future.microtask(() => loadNotifications());
    return const ParentNotificationsState(isLoading: true);
  }

  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else if (state.notifications.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final res = await _repository.getNotifications(page: 1, limit: _pageSize);
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      state = state.copyWith(
        notifications: res.data,
        isLoading: false,
        isRefreshing: false,
        currentPage: 1,
        hasMore: hasNext,
        error: null,
        clearLoadMoreError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    } finally {
      _isFetching = false;
    }
  }

  /// Paginated load more: strictly checks beforehand if there is more data.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading || _isFetching) {
      return;
    }
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await _repository.getNotifications(
        page: nextPage,
        limit: _pageSize,
      );
      final hasNext = res.meta?.hasNextPage ?? (res.data.length >= _pageSize);
      final existingIds = state.notifications.map((n) => n.id).toSet();
      final newItems =
          res.data.where((n) => !existingIds.contains(n.id)).toList();

      state = state.copyWith(
        notifications: [...state.notifications, ...newItems],
        currentPage: nextPage,
        hasMore: hasNext,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: e.toString(),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => loadNotifications(isRefresh: true);

  Future<void> markAsRead(String id) async {
    // Optimistic local update
    final currentList = state.notifications;
    final updatedList = currentList.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = state.copyWith(notifications: updatedList);

    try {
      await _repository.markNotificationAsRead(id);
    } catch (_) {
      // Remote call completed with best-effort
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic local update
    final updatedList =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    state = state.copyWith(notifications: updatedList);

    try {
      await _repository.markAllNotificationsAsRead();
    } catch (_) {
      // Remote call completed with best-effort
    }
  }
}

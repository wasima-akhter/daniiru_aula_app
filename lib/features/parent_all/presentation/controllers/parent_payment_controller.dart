import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';

class ParentPaymentState {
  final List<InvoiceModel> invoices;
  final String selectedPaymentMethod;
  final bool isProcessing;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? loadMoreError;

  const ParentPaymentState({
    this.invoices = const [],
    this.selectedPaymentMethod = 'card',
    this.isProcessing = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.loadMoreError,
  });

  List<InvoiceModel> get pendingInvoices =>
      invoices.where((i) => !i.isPaid).toList();
  List<InvoiceModel> get paidInvoices =>
      invoices.where((i) => i.isPaid).toList();

  ParentPaymentState copyWith({
    List<InvoiceModel>? invoices,
    String? selectedPaymentMethod,
    bool? isProcessing,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ParentPaymentState(
      invoices: invoices ?? this.invoices,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
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

final parentPaymentControllerProvider =
    NotifierProvider<ParentPaymentController, ParentPaymentState>(
      ParentPaymentController.new,
    );

class ParentPaymentController extends Notifier<ParentPaymentState> {
  static const int _pageSize = 20;
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  ParentPaymentState build() {
    Future.microtask(() => loadInvoices());
    return const ParentPaymentState(isLoading: true);
  }

  Future<void> loadInvoices({String? status}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMore: true,
      clearLoadMoreError: true,
    );
    try {
      final res = await _repository.getInvoices(
        status: status,
        page: 1,
        limit: _pageSize,
      );
      state = state.copyWith(
        invoices: res.items,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMore: res.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Paginated load more: strictly checks beforehand if there is more data.
  Future<void> loadMore({String? status}) async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.currentPage + 1;
    try {
      final res = await _repository.getInvoices(
        status: status,
        page: nextPage,
        limit: _pageSize,
      );
      final existingIds = state.invoices.map((i) => i.id).toSet();
      final newItems = res.items.where((i) => !existingIds.contains(i.id)).toList();
      state = state.copyWith(
        invoices: [...state.invoices, ...newItems],
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

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  Future<bool> processPayment(String invoiceId) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      await _repository.payInvoice(invoiceId, state.selectedPaymentMethod);
      final updated = await _repository.getInvoices(page: 1, limit: _pageSize);
      state = state.copyWith(
        invoices: updated.items,
        isProcessing: false,
        currentPage: 1,
        hasMore: updated.hasMore,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

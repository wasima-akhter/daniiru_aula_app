import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/config/stripe_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/service/language/language_provider.dart';
import '../../../../core/services/stripe/stripe_payment_service.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';

export '../../../../core/config/stripe_config.dart';
export '../../../../core/services/stripe/stripe_payment_service.dart';

enum InvoiceFilterTab { all, pending, paid }

class ParentPaymentState {
  final List<InvoiceModel> invoices;
  final String selectedPaymentMethod;
  final InvoiceFilterTab selectedTab;
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
    this.selectedTab = InvoiceFilterTab.all,
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

  List<InvoiceModel> get filteredInvoices {
    switch (selectedTab) {
      case InvoiceFilterTab.pending:
        return pendingInvoices;
      case InvoiceFilterTab.paid:
        return paidInvoices;
      case InvoiceFilterTab.all:
        return invoices;
    }
  }

  double get totalPendingAmount =>
      pendingInvoices.fold(0.0, (sum, i) => sum + i.amount);

  ParentPaymentState copyWith({
    List<InvoiceModel>? invoices,
    String? selectedPaymentMethod,
    InvoiceFilterTab? selectedTab,
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
      selectedTab: selectedTab ?? this.selectedTab,
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
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        if (next.user != null) {
          state = const ParentPaymentState(isLoading: true);
          Future.microtask(() => loadInvoices());
        } else {
          state = const ParentPaymentState();
        }
      }
    });
    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        Future.microtask(() => loadInvoices());
      }
    });
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

  void selectTab(InvoiceFilterTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  Future<void> refresh({String? status}) => loadInvoices(status: status);

  /// Initiates payment for an invoice via Stripe PaymentSheet safely with edge cases.
  Future<StripePaymentResult> payInvoiceWithStripe(InvoiceModel invoice) async {
    // Edge case 1: Stripe public key not configured yet
    if (!StripeConfig.isConfigured) {
      return StripePaymentResult.notConfigured();
    }

    // Edge case 2: Invoice is already marked as paid
    if (invoice.isPaid) {
      return StripePaymentResult.alreadyPaid();
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // 1. Request clientSecret from backend
      final clientSecret = await _repository.payInvoice(
        invoice.id,
        state.selectedPaymentMethod,
      );

      if (clientSecret == null || clientSecret.trim().isEmpty) {
        state = state.copyWith(isProcessing: false);
        return StripePaymentResult.failed(
          message: 'Empty client secret returned from server',
        );
      }

      // 2. Present native Stripe Payment Sheet
      final stripeService = ref.read(stripePaymentServiceProvider);
      final result = await stripeService.presentPaymentSheet(
        clientSecret: clientSecret,
        merchantDisplayName: StripeConfig.merchantDisplayName,
      );

      // 3. Handle payment result
      if (result.isSuccess) {
        final now = DateTime.now();
        String formattedDate;
        try {
          formattedDate =
              DateFormat('d MMM yyyy', LanguageNotifier.activeLanguageCode)
                  .format(now);
        } catch (_) {
          try {
            formattedDate = DateFormat('d MMM yyyy').format(now);
          } catch (_) {
            formattedDate = '${now.day}/${now.month}/${now.year}';
          }
        }

        // Optimistically mark invoice as paid in local state
        final updated = state.invoices.map((inv) {
          if (inv.id == invoice.id) {
            return inv.copyWith(
              isPaid: true,
              paidDate: formattedDate,
              receiptNumber:
                  'REC-${now.millisecondsSinceEpoch % 100000}',
            );
          }
          return inv;
        }).toList();

        state = state.copyWith(invoices: updated, isProcessing: false);

        // Synchronize with server
        try {
          final res = await _repository.getInvoices(page: 1, limit: _pageSize);
          state = state.copyWith(
            invoices: res.items,
            currentPage: 1,
            hasMore: res.hasMore,
          );
        } catch (_) {}

        return result;
      }

      state = state.copyWith(isProcessing: false);
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(isProcessing: false);
      final rawLower = e.rawMessage.toLowerCase();
      if (e.statusCode == 400 &&
          (rawLower.contains('already paid') ||
              rawLower.contains('ya está pagada') ||
              rawLower.contains('not pending'))) {
        refresh();
        return StripePaymentResult.alreadyPaid(message: e.rawMessage);
      }
      return StripePaymentResult.failed(message: e.message);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return StripePaymentResult.failed(message: e.toString());
    }
  }

  /// Backward-compatible payment processor method.
  Future<bool> processPayment(String invoiceId) async {
    final invoice = state.invoices.firstWhere(
      (i) => i.id == invoiceId,
      orElse: () => InvoiceModel(
        id: invoiceId,
        concept: '',
        monthYear: '',
        amount: 0,
        dueDate: '',
        isPaid: false,
      ),
    );
    final result = await payInvoiceWithStripe(invoice);
    return result.isSuccess;
  }
}

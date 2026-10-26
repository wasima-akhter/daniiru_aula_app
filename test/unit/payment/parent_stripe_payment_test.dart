import 'package:aula360/core/network/api_exception.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/domain/models/parent_models.dart';
import 'package:aula360/features/parent_all/domain/repositories/parent_repository.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_payment_controller.dart';
import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStripePaymentService implements StripePaymentService {
  StripePaymentResult nextResult = StripePaymentResult.success();
  String? lastClientSecret;
  String? lastMerchantDisplayName;
  int callCount = 0;

  @override
  Future<StripePaymentResult> presentPaymentSheet({
    required String clientSecret,
    String? merchantDisplayName,
  }) async {
    callCount++;
    lastClientSecret = clientSecret;
    lastMerchantDisplayName = merchantDisplayName;
    return nextResult;
  }
}

class MockParentRepository extends Fake implements ParentRepository {
  List<InvoiceModel> mockInvoices;
  String? returnClientSecret = 'pi_test_secret_123';
  Exception? payInvoiceException;
  int payInvoiceCalls = 0;
  String? lastPaidInvoiceId;

  MockParentRepository({required this.mockInvoices});

  @override
  Future<PaginatedResult<InvoiceModel>> getInvoices({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return PaginatedResult<InvoiceModel>(data: mockInvoices, meta: null);
  }

  @override
  Future<String?> payInvoice(String invoiceId, [String? paymentMethod]) async {
    payInvoiceCalls++;
    lastPaidInvoiceId = invoiceId;
    if (payInvoiceException != null) {
      throw payInvoiceException!;
    }
    mockInvoices = mockInvoices.map((i) {
      if (i.id == invoiceId) {
        return i.copyWith(isPaid: true);
      }
      return i;
    }).toList();
    return returnClientSecret;
  }
}

void main() {
  group('StripeConfig', () {
    test('isConfigured is false when publishableKey is empty', () {
      StripeConfig.publishableKey = '';
      expect(StripeConfig.isConfigured, isFalse);
    });

    test('isConfigured is true when publishableKey is populated', () {
      StripeConfig.publishableKey = 'pk_test_1234567890abcdef';
      expect(StripeConfig.isConfigured, isTrue);
    });
  });

  group('ParentPaymentController with Stripe Edge Cases', () {
    const testInvoice = InvoiceModel(
      id: 'inv-test-1',
      concept: 'Monthly Tuition',
      monthYear: 'Octubre 2026',
      amount: 120.0,
      dueDate: '2026-10-30',
      isPaid: false,
      feeTitle: 'Tuition Fee',
      studentName: 'Alex Doe',
    );

    late MockStripePaymentService mockStripeService;
    late MockParentRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockStripeService = MockStripePaymentService();
      mockRepo = MockParentRepository(mockInvoices: [testInvoice]);

      container = ProviderContainer(
        overrides: [
          parentRepositoryProvider.overrideWithValue(mockRepo),
          stripePaymentServiceProvider.overrideWithValue(mockStripeService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      StripeConfig.publishableKey = '';
    });

    test('1. Edge Case: Returns notConfigured when Stripe key is not set', () async {
      StripeConfig.publishableKey = '';

      final controller = container.read(parentPaymentControllerProvider.notifier);
      final result = await controller.payInvoiceWithStripe(testInvoice);

      expect(result.status, StripePaymentStatus.notConfigured);
      expect(result.isNotConfigured, isTrue);
      expect(mockStripeService.callCount, 0);
      expect(mockRepo.payInvoiceCalls, 0);
    });

    test('2. Edge Case: Returns alreadyPaid if invoice is already paid', () async {
      StripeConfig.publishableKey = 'pk_test_sample_key';

      final paidInvoice = testInvoice.copyWith(isPaid: true);
      final controller = container.read(parentPaymentControllerProvider.notifier);
      final result = await controller.payInvoiceWithStripe(paidInvoice);

      expect(result.status, StripePaymentStatus.alreadyPaid);
      expect(result.isAlreadyPaid, isTrue);
      expect(mockStripeService.callCount, 0);
      expect(mockRepo.payInvoiceCalls, 0);
    });

    test('3. Edge Case: Handles 400 Already Paid from server gracefully', () async {
      StripeConfig.publishableKey = 'pk_test_sample_key';
      mockRepo.payInvoiceException = ApiException(
        statusCode: 400,
        message: 'Invoice is already paid',
      );

      final controller = container.read(parentPaymentControllerProvider.notifier);
      final result = await controller.payInvoiceWithStripe(testInvoice);

      expect(result.status, StripePaymentStatus.alreadyPaid);
      expect(result.isAlreadyPaid, isTrue);
      expect(mockRepo.payInvoiceCalls, 1);
      expect(mockStripeService.callCount, 0);
    });

    test('4. Edge Case: Handles user cancellation in Stripe Sheet', () async {
      StripeConfig.publishableKey = 'pk_test_sample_key';
      mockStripeService.nextResult = StripePaymentResult.canceled();

      final controller = container.read(parentPaymentControllerProvider.notifier);
      final result = await controller.payInvoiceWithStripe(testInvoice);

      expect(result.status, StripePaymentStatus.canceled);
      expect(result.isCanceled, isTrue);
      expect(mockRepo.payInvoiceCalls, 1);
      expect(mockStripeService.callCount, 1);
      expect(mockStripeService.lastClientSecret, 'pi_test_secret_123');
    });

    test('5. Edge Case: Handles card decline in Stripe Sheet', () async {
      StripeConfig.publishableKey = 'pk_test_sample_key';
      mockStripeService.nextResult = StripePaymentResult.declined(
        message: 'Your card was declined by the issuer.',
      );

      final controller = container.read(parentPaymentControllerProvider.notifier);
      final result = await controller.payInvoiceWithStripe(testInvoice);

      expect(result.status, StripePaymentStatus.declined);
      expect(result.isDeclined, isTrue);
      expect(result.message, 'Your card was declined by the issuer.');
      expect(mockStripeService.callCount, 1);
    });

    test('6. Edge Case: Handles empty clientSecret from server', () async {
      StripeConfig.publishableKey = 'pk_test_sample_key';
      mockRepo.returnClientSecret = '';

      final controller = container.read(parentPaymentControllerProvider.notifier);
      final result = await controller.payInvoiceWithStripe(testInvoice);

      expect(result.status, StripePaymentStatus.failed);
      expect(result.isFailed, isTrue);
      expect(mockStripeService.callCount, 0);
    });

    test('7. Happy Path: Successful payment marks invoice paid and syncs state', () async {
      StripeConfig.publishableKey = 'pk_test_sample_key';
      mockStripeService.nextResult = StripePaymentResult.success();

      // Seed state
      await container.read(parentPaymentControllerProvider.notifier).loadInvoices();

      final controller = container.read(parentPaymentControllerProvider.notifier);
      final result = await controller.payInvoiceWithStripe(testInvoice);

      expect(result.status, StripePaymentStatus.success);
      expect(result.isSuccess, isTrue);
      expect(mockStripeService.callCount, 1);
      expect(mockStripeService.lastClientSecret, 'pi_test_secret_123');
      expect(mockStripeService.lastMerchantDisplayName, StripeConfig.merchantDisplayName);

      // Verify state was optimistically updated with isPaid = true
      final state = container.read(parentPaymentControllerProvider);
      final updated = state.invoices.firstWhere((i) => i.id == testInvoice.id);
      expect(updated.isPaid, isTrue);
    });
  });
}

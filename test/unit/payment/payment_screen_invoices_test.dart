import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/parent_all/data/dtos/parent_invoice_dto.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/domain/models/parent_models.dart';
import 'package:aula360/features/parent_all/domain/repositories/parent_repository.dart';
import 'package:aula360/features/parent_all/payment/payment_screen.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_payment_controller.dart';
import 'package:aula360/features/share/widgets/paginator/paginator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeParentRepository extends Fake implements ParentRepository {
  final List<InvoiceModel> mockInvoices;

  FakeParentRepository({required this.mockInvoices});

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
    return 'pi_mock_secret';
  }
}

class FakeLanguageNotifier extends LanguageNotifier {
  final AppLanguage appLang;
  FakeLanguageNotifier(this.appLang);

  @override
  Future<LanguageState> build() async {
    return LanguageState(
      language: appLang,
      strings: const {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parent Invoices DTO & Domain Mapping', () {
    test('parses API response data with multiple pending and paid invoices', () {
      final rawData = [
        {
          'id': '568a46f7-7ae3-4181-951c-0bece20d5d48',
          'feeTitle': 'new 2',
          'studentName': 'dfddf',
          'amount': 43,
          'currency': 'EUR',
          'dueDate': '2026-10-26T23:59:59.000Z',
          'status': 'PENDING',
          'paidAt': null,
        },
        {
          'id': '34e0cdbd-ed90-45d3-aa20-594eef5773d8',
          'feeTitle': 'new payment',
          'studentName': 'dfddf',
          'amount': 150,
          'currency': 'EUR',
          'dueDate': '2026-10-26T23:59:59.000Z',
          'status': 'PENDING',
          'paidAt': null,
        },
        {
          'id': 'a0a95904-6d28-40ee-842b-b2ce08ca0b4b',
          'feeTitle': 'new',
          'studentName': 'dffffd',
          'amount': 150,
          'currency': 'EUR',
          'dueDate': '2026-10-15T23:59:59.000Z',
          'status': 'PAID',
          'paidAt': '2026-10-25T09:25:21.589Z',
        },
      ];

      final dtos = rawData.map(ParentInvoiceDto.fromJson).toList();
      expect(dtos.length, 3);
      expect(dtos[0].feeTitle, 'new 2');
      expect(dtos[0].amount, 43.0);
      expect(dtos[0].status, 'PENDING');

      final models = dtos.map((d) => d.toModel()).toList();
      expect(models.length, 3);
      expect(models[0].isPaid, isFalse);
      expect(models[1].isPaid, isFalse);
      expect(models[2].isPaid, isTrue);
      expect(models[2].receiptNumber, startsWith('REC-A0A959'));
    });
  });

  group('TuitionPaymentScreen All Invoices & Localization', () {
    final mockInvoices = [
      const InvoiceModel(
        id: 'inv-1',
        concept: 'new 2 (dfddf)',
        monthYear: 'Octubre 2026',
        amount: 43.0,
        dueDate: '26 Oct 2026',
        isPaid: false,
        feeTitle: 'new 2',
        studentName: 'dfddf',
      ),
      const InvoiceModel(
        id: 'inv-2',
        concept: 'new payment (dfddf)',
        monthYear: 'Octubre 2026',
        amount: 150.0,
        dueDate: '26 Oct 2026',
        isPaid: false,
        feeTitle: 'new payment',
        studentName: 'dfddf',
      ),
      const InvoiceModel(
        id: 'inv-3',
        concept: 'new (dffffd)',
        monthYear: 'Octubre 2026',
        amount: 150.0,
        dueDate: '15 Oct 2026',
        isPaid: true,
        paidDate: '25 Oct 2026',
        receiptNumber: 'REC-A0A959',
        feeTitle: 'new',
        studentName: 'dffffd',
      ),
    ];

    Widget buildTestScreen([AppLanguage language = AppLanguage.spanish]) {
      return ProviderScope(
        overrides: [
          parentRepositoryProvider.overrideWithValue(
            FakeParentRepository(mockInvoices: mockInvoices),
          ),
          languageProvider.overrideWith(() => FakeLanguageNotifier(language)),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const MaterialApp(
            home: TuitionPaymentScreen(),
          ),
        ),
      );
    }

    testWidgets('displays all invoices and summary banner in Spanish when Spanish is selected', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_language': 'es'});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Summary banner should show total pending amount (43 + 150 = 193.00 €) and Spanish text
      expect(find.text('193.00 €'), findsOneWidget);
      expect(find.text('2 pendientes'), findsOneWidget);
      expect(find.text('Total pendiente de pago'), findsOneWidget);

      // Filter tabs in Spanish
      expect(find.text('Todos (3)'), findsOneWidget);
      expect(find.text('Pendientes (2)'), findsOneWidget);
      expect(find.text('Pagados (1)'), findsOneWidget);

      // All invoices should be visible in the list
      expect(find.text('new 2'), findsOneWidget);
      expect(find.text('new payment'), findsOneWidget);
      expect(find.text('new'), findsOneWidget);

      // Status badges should be rendered in Spanish
      expect(find.text('PENDIENTE'), findsNWidgets(2));
      expect(find.text('PAGADO'), findsOneWidget);
    });

    testWidgets('allows entering checkout for an invoice and returning back easily in Spanish', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_language': 'es'});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap on pay for first invoice (43.00 €)
      final payButton = find.text('Pagar cuota (43.00 €)');
      expect(payButton, findsOneWidget);
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // Should now be in checkout view with translated strings
      expect(find.text('Volver a mis facturas'), findsOneWidget);
      expect(find.text('Cancelar y volver'), findsOneWidget);

      // User decides NOT to pay: taps 'Volver a mis facturas'
      await tester.tap(find.text('Volver a mis facturas'));
      await tester.pumpAndSettle();

      // Returns back to invoices list easily
      expect(find.text('193.00 €'), findsOneWidget);
      expect(find.text('new 2'), findsOneWidget);
      expect(find.text('new payment'), findsOneWidget);
    });

    testWidgets('displays all invoices and checkout properly in English when English is selected', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(AppLanguage.english));
      await tester.pumpAndSettle();

      // Summary banner should show total pending amount and English text
      expect(find.text('193.00 €'), findsOneWidget);
      expect(find.text('2 pending'), findsOneWidget);
      expect(find.text('Total pending payment'), findsOneWidget);

      // Filter tabs in English
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Pending (2)'), findsOneWidget);
      expect(find.text('Paid (1)'), findsOneWidget);

      // Status badges should be rendered in English
      expect(find.text('PENDING'), findsNWidgets(2));
      expect(find.text('PAID'), findsOneWidget);

      // Tap on pay for first invoice in English
      final payButton = find.text('Pay fee (43.00 €)');
      expect(payButton, findsOneWidget);
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // Should now be in checkout view with English strings
      expect(find.text('Back to my invoices'), findsOneWidget);
      expect(find.text('Cancel and return'), findsOneWidget);
    });
  });
}

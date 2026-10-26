import '../../share/export/screen_export.dart';
import '../domain/models/parent_models.dart';
import '../presentation/controllers/parent_children_controller.dart';
import '../presentation/controllers/parent_payment_controller.dart';

class TuitionPaymentScreen extends ConsumerStatefulWidget {
  final InvoiceModel? selectedInvoice;

  const TuitionPaymentScreen({super.key, this.selectedInvoice});

  @override
  ConsumerState<TuitionPaymentScreen> createState() =>
      _TuitionPaymentScreenState();
}

class _TuitionPaymentScreenState extends ConsumerState<TuitionPaymentScreen> {
  InvoiceModel? _selectedInvoiceForPay;
  bool saveCard = true;

  @override
  void initState() {
    super.initState();
    _selectedInvoiceForPay = widget.selectedInvoice;
  }

  @override
  void didUpdateWidget(covariant TuitionPaymentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedInvoice != oldWidget.selectedInvoice) {
      _selectedInvoiceForPay = widget.selectedInvoice;
    }
  }

  void _handleBack() {
    if (_selectedInvoiceForPay != null) {
      setState(() {
        _selectedInvoiceForPay = null;
      });
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePath.navigationPages);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(parentPaymentControllerProvider);
    final paymentController = ref.read(
      parentPaymentControllerProvider.notifier,
    );
    final activeChild = ref
        .watch(parentChildrenControllerProvider)
        .selectedChild;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F7FC),
        appBar: _paymentAppBar(paymentController),
        body: SafeArea(
          child: _selectedInvoiceForPay != null
              ? _checkoutView(
                  paymentState,
                  paymentController,
                  _selectedInvoiceForPay!,
                  activeChild,
                )
              : _invoicesListView(paymentState, paymentController, activeChild),
        ),
      ),
    );
  }

  PreferredSizeWidget _paymentAppBar(
    ParentPaymentController paymentController,
  ) {
    final isCheckout = _selectedInvoiceForPay != null;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: _handleBack,
        icon: Icon(Icons.arrow_back, color: AppColors.primaryDark, size: 21.sp),
      ),
      title: Text(
        isCheckout
            ? ref.watchTr(AppStrings.tuitionPaymentTitle)
            : ref.watchTr(AppStrings.paymentsTitle),
        style: TxtStyle.titleLarge(
          color: AppColors.primaryDark,
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        if (!isCheckout)
          IconButton(
            onPressed: () => paymentController.refresh(),
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryDark,
              size: 20.sp,
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(height: 1, color: AppColors.backgroundsLinesColor),
      ),
    );
  }

  // ===============================================================
  // INVOICES LIST VIEW (Shows all parent invoices)
  // ===============================================================

  Widget _invoicesListView(
    ParentPaymentState state,
    ParentPaymentController controller,
    ChildModel? activeChild,
  ) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
              SizedBox(height: 12.h),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TxtStyle.bodyMedium(
                  fontSize: 14.sp,
                  color: AppColors.subtitleTextColor,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () => controller.refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(ref.watchTr(AppStrings.retry)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayList = state.filteredInvoices;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 30.h),
        children: [
          _summaryBanner(state),
          _filterTabs(state, controller),
          if (displayList.isEmpty)
            _emptyView(state, controller)
          else
            ...displayList.map(
              (invoice) => _invoiceCard(context, invoice, activeChild),
            ),
        ],
      ),
    );
  }

  Widget _summaryBanner(ParentPaymentState state) {
    final pendingCount = state.pendingInvoices.length;
    final totalPending = state.totalPendingAmount;
    final hasPending = pendingCount > 0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: hasPending ? AppColors.primaryDark : const Color(0xFF0C8A8A),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPending
                  ? Icons.account_balance_wallet_outlined
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasPending
                      ? ref.watchTr(AppStrings.totalPendingPayment)
                      : ref.watchTr(AppStrings.paymentsUpToDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TxtStyle.bodyMedium(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  hasPending
                      ? '${totalPending.toStringAsFixed(2)} €'
                      : '0.00 €',
                  style: TxtStyle.titleLarge(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                hasPending
                    ? '$pendingCount ${pendingCount > 1 ? ref.watchTr(AppStrings.pendingPluralCountLabel) : ref.watchTr(AppStrings.pendingCountLabel)}'
                    : ref.watchTr(AppStrings.noDebts),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TxtStyle.titleLarge(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTabs(
    ParentPaymentState state,
    ParentPaymentController controller,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          _filterChipItem(
            label: ref.watchTr(AppStrings.allTab),
            count: state.invoices.length,
            isSelected: state.selectedTab == InvoiceFilterTab.all,
            onTap: () => controller.selectTab(InvoiceFilterTab.all),
          ),
          SizedBox(width: 8.w),
          _filterChipItem(
            label: ref.watchTr(AppStrings.pendingTab),
            count: state.pendingInvoices.length,
            isSelected: state.selectedTab == InvoiceFilterTab.pending,
            onTap: () => controller.selectTab(InvoiceFilterTab.pending),
          ),
          SizedBox(width: 8.w),
          _filterChipItem(
            label: ref.watchTr(AppStrings.paidTab),
            count: state.paidInvoices.length,
            isSelected: state.selectedTab == InvoiceFilterTab.paid,
            onTap: () => controller.selectTab(InvoiceFilterTab.paid),
          ),
        ],
      ),
    );
  }

  Widget _filterChipItem({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.primaryDark : AppColors.border,
            ),
          ),
          child: Text(
            '$label ($count)',
            style: TxtStyle.titleLarge(
              color: isSelected ? Colors.white : AppColors.subtitleTextColor,
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _invoiceCard(
    BuildContext context,
    InvoiceModel invoice,
    ChildModel? activeChild,
  ) {
    final isPaid = invoice.isPaid;
    final studentName =
        (invoice.studentName != null && invoice.studentName!.isNotEmpty)
        ? invoice.studentName!
        : (activeChild?.name ?? ref.watchTr(AppStrings.studentLabel));

    final initials =
        (invoice.studentName != null && invoice.studentName!.isNotEmpty)
        ? (invoice.studentName!.trim().split(' ').length > 1
              ? '${invoice.studentName!.trim().split(' ')[0][0]}${invoice.studentName!.trim().split(' ')[1][0]}'
                    .toUpperCase()
              : invoice.studentName!.substring(0, 1).toUpperCase())
        : (activeChild?.initials ?? 'ST');

    final title = invoice.feeTitle ?? invoice.concept;
    final invoiceNum =
        '#${invoice.id.length > 8 ? invoice.id.substring(0, 8).toUpperCase() : invoice.id}';
    final amountFormatted = '${invoice.amount.toStringAsFixed(2)} €';
    final paidPrefix = ref.watchTr(AppStrings.paidDatePrefix);
    final duePrefix = ref.watchTr(AppStrings.dueDatePrefix);
    final statusPaid = ref.watchTr(AppStrings.statusPaid);
    final statusPending = ref.watchTr(AppStrings.statusPending);
    final dateText = isPaid
        ? (invoice.paidDate != null
              ? '$paidPrefix ${invoice.paidDate}'
              : statusPaid)
        : '$duePrefix ${invoice.dueDate}';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFE5FAF2) : AppColors.blueSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: TxtStyle.titleLarge(
                    color: isPaid
                        ? AppColors.emeraldGreenColor
                        : AppColors.primaryDark,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TxtStyle.titleLarge(
                        color: AppColors.text,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$studentName • $invoiceNum',
                      style: TxtStyle.bodyMedium(
                        color: AppColors.subtitleTextColor,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFE5FAF2)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(
                    color: isPaid
                        ? AppColors.emeraldGreenColor.withValues(alpha: 0.3)
                        : AppColors.orangeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isPaid ? statusPaid : statusPending,
                  style: TxtStyle.titleLarge(
                    color: isPaid
                        ? AppColors.emeraldGreenColor
                        : AppColors.orangeColor,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: AppColors.backgroundsLinesColor),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle_outline
                          : Icons.calendar_today_outlined,
                      size: 14.sp,
                      color: AppColors.subtitleTextColor,
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        dateText,
                        overflow: TextOverflow.ellipsis,
                        style: TxtStyle.bodyMedium(
                          color: AppColors.subtitleTextColor,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                amountFormatted,
                style: TxtStyle.titleLarge(
                  color: AppColors.primaryDark,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: isPaid
                ? OutlinedButton.icon(
                    onPressed: () {
                      context.push(
                        RoutePath.paymentReceipt,
                        extra: {'invoice': invoice, 'child': activeChild},
                      );
                    },
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      size: 16.sp,
                      color: AppColors.primaryDark,
                    ),
                    label: Text(
                      ref.watchTr(AppStrings.previewReceipt),
                      style: TxtStyle.titleLarge(
                        color: AppColors.primaryDark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedInvoiceForPay = invoice;
                      });
                    },
                    icon: Icon(
                      Icons.lock_outline,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                    label: Text(
                      '${ref.watchTr(AppStrings.payFee)} ($amountFormatted)',
                      style: TxtStyle.titleLarge(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView(
    ParentPaymentState state,
    ParentPaymentController controller,
  ) {
    final isPendingTab = state.selectedTab == InvoiceFilterTab.pending;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: isPendingTab
                    ? const Color(0xFFE5FAF2)
                    : AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isPendingTab
                      ? Icons.check_circle_outline
                      : Icons.receipt_long_outlined,
                  color: isPendingTab
                      ? AppColors.emeraldGreenColor
                      : AppColors.primaryDark,
                  size: 34.sp,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              isPendingTab
                  ? ref.watchTr(AppStrings.noPendingPayments)
                  : ref.watchTr(AppStrings.noInvoicesFound),
              textAlign: TextAlign.center,
              style: TxtStyle.titleLarge(
                color: AppColors.text,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isPendingTab
                  ? ref.watchTr(AppStrings.noPendingPaymentsDesc)
                  : ref.watchTr(AppStrings.noInvoicesFoundDesc),
              textAlign: TextAlign.center,
              style: TxtStyle.bodyMedium(
                color: AppColors.subtitleTextColor,
                fontSize: 14.sp,
              ),
            ),
            if (isPendingTab && state.paidInvoices.isNotEmpty) ...[
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: () {
                  controller.selectTab(InvoiceFilterTab.paid);
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: Text(ref.watchTr(AppStrings.viewPaymentHistory)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // CHECKOUT VIEW (Payment details & execution for selected invoice)
  // ===============================================================

  Widget _checkoutView(
    ParentPaymentState paymentState,
    ParentPaymentController paymentController,
    InvoiceModel invoice,
    ChildModel? activeChild,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14.w, 15.h, 14.w, 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedInvoiceForPay = null;
              });
            },
            borderRadius: BorderRadius.circular(6.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 16.sp,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    ref.watchTr(AppStrings.backToInvoices),
                    style: TxtStyle.titleLarge(
                      color: AppColors.primaryDark,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          _studentInvoiceCard(activeChild, invoice),
          SizedBox(height: 20.h),
          _sectionTitle(ref.watchTr(AppStrings.paymentMethodTitle)),
          SizedBox(height: 10.h),
          _cardDetails(),
          SizedBox(height: 10.h),
          _saveCard(),
          SizedBox(height: 20.h),
          _payButton(paymentState, paymentController, invoice, activeChild),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Text(
                ref.watchTr(AppStrings.cancelAndReturn),
                style: TxtStyle.titleLarge(
                  color: AppColors.subtitleTextColor,
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentInvoiceCard(ChildModel? child, InvoiceModel? invoice) {
    final initials =
        (invoice?.studentName != null && invoice!.studentName!.isNotEmpty)
        ? (invoice.studentName!.trim().split(' ').length > 1
              ? '${invoice.studentName!.trim().split(' ')[0][0]}${invoice.studentName!.trim().split(' ')[1][0]}'
                    .toUpperCase()
              : invoice.studentName!.substring(0, 1).toUpperCase())
        : (child?.initials ?? 'ST');

    final name =
        (invoice?.studentName != null && invoice!.studentName!.isNotEmpty)
        ? invoice.studentName!
        : (child?.name ?? ref.watchTr(AppStrings.studentLabel));

    final gradeClass = child != null
        ? '${child.grade} • ${child.classroom}'
        : '';
    final invoiceNum = invoice != null
        ? '#${invoice.id.length > 8 ? invoice.id.substring(0, 8).toUpperCase() : invoice.id}'
        : '';
    final concept = invoice?.concept ?? '';
    final amountFormatted = invoice != null
        ? '${invoice.amount.toStringAsFixed(2)} €'
        : '0.00 €';
    final duePrefix = ref.watchTr(AppStrings.dueDatePrefix);
    final dueDateText = invoice != null ? '$duePrefix ${invoice.dueDate}' : '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.blueSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: TxtStyle.titleLarge(
                    color: AppColors.primaryDark,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TxtStyle.titleLarge(
                        color: AppColors.text,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (gradeClass.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        gradeClass,
                        style: TxtStyle.titleLarge(
                          color: AppColors.subtitleTextColor,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Text(
                  '${ref.watchTr(AppStrings.invoiceLabel)} $invoiceNum',
                  style: TxtStyle.titleLarge(
                    color: AppColors.primaryDark,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(height: 1, color: AppColors.backgroundsLinesColor),
          SizedBox(height: 10.h),
          _invoiceRow(concept, amountFormatted),
          SizedBox(height: 12.h),
          Divider(height: 1, color: AppColors.backgroundsLinesColor),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.watchTr(AppStrings.totalToPay),
                      style: TxtStyle.titleLarge(
                        color: AppColors.subtitleTextColor,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      amountFormatted,
                      style: TxtStyle.titleLarge(
                        color: AppColors.primaryDark,
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (dueDateText.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.softSlateBgColor,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Text(
                    dueDateText,
                    style: TxtStyle.titleLarge(
                      color: AppColors.subtitleTextColor,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String title, String amount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TxtStyle.titleLarge(
              color: AppColors.subtitleTextColor,
              fontSize: 15.sp,
            ),
          ),
        ),
        Text(
          amount,
          style: TxtStyle.titleLarge(
            color: AppColors.text,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Row(
          children: [
            Icon(Icons.lock, color: AppColors.subtitleTextColor, size: 11.sp),
            SizedBox(width: 3.w),
            Text(
              ref.watchTr(AppStrings.processedByStripe),
              style: TxtStyle.titleLarge(
                color: AppColors.subtitleTextColor,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _field(
            title: ref.watchTr(AppStrings.cardNumber),
            value: '4242 4242 4242 4242',
            trailing: Row(
              children: [
                _cardBrand('VISA'),
                SizedBox(width: 4.w),
                _cardBrand('MC'),
                SizedBox(width: 4.w),
                _cardBrand('AMEX'),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  title: ref.watchTr(AppStrings.expiration),
                  value: '08 / 27',
                  borderRight: true,
                ),
              ),
              Expanded(
                child: _field(title: ref.watchTr(AppStrings.cvc), value: '123'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  title: ref.watchTr(AppStrings.country),
                  value: 'España',
                  borderRight: true,
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    size: 15.sp,
                    color: AppColors.subtitleTextColor,
                  ),
                ),
              ),
              Expanded(
                child: _field(
                  title: ref.watchTr(AppStrings.postalCode),
                  value: '28013',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String title,
    required String value,
    Widget? trailing,
    bool borderRight = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(9.w, 9.h, 9.w, 9.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.backgroundsLinesColor),
          right: borderRight
              ? BorderSide(color: AppColors.backgroundsLinesColor)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TxtStyle.titleLarge(
              color: AppColors.blueTextColor,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TxtStyle.titleLarge(
                    color: AppColors.text,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardBrand(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.softSlateBgColor,
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Text(
        text,
        style: TxtStyle.titleLarge(
          color: AppColors.blueTextColor,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _saveCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark, color: AppColors.primaryDark, size: 14.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watchTr(AppStrings.saveCardFuture),
                  style: TxtStyle.titleLarge(
                    color: AppColors.text,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  ref.watchTr(AppStrings.autoBillingSubtitle),
                  style: TxtStyle.titleLarge(
                    color: AppColors.subtitleTextColor,
                    fontSize: 13.5.sp,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: saveCard,
            onChanged: (value) {
              setState(() {
                saveCard = value;
              });
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _payButton(
    ParentPaymentState state,
    ParentPaymentController controller,
    InvoiceModel? invoice, [
    ChildModel? child,
  ]) {
    final amountFormatted = invoice != null
        ? '${invoice.amount.toStringAsFixed(2)} €'
        : '0.00 €';

    return SizedBox(
      width: double.infinity,
      child: AulaPrimaryButton(
        text: '${ref.watchTr(AppStrings.payNowBtn)} $amountFormatted',
        isLoading: state.isProcessing,
        backgroundColor: AppColors.primaryDark,
        leading: Icon(Icons.lock_outline, color: Colors.white, size: 15.sp),
        trailing: const SizedBox.shrink(),
        onTapAsync: () async {
          if (invoice == null) return;
          await _handlePayment(controller, invoice, child);
        },
      ),
    );
  }

  Future<void> _handlePayment(
    ParentPaymentController controller,
    InvoiceModel invoice,
    ChildModel? child,
  ) async {
    final result = await controller.payInvoiceWithStripe(invoice);

    if (!mounted) return;

    if (result.isSuccess) {
      context.push(
        RoutePath.paymentReceipt,
        extra: {
          'invoice': invoice.copyWith(
            isPaid: true,
            paidDate: 'Hoy',
            receiptNumber:
                'REC-${DateTime.now().millisecondsSinceEpoch % 100000}',
          ),
          'child': child,
        },
      );
      setState(() {
        _selectedInvoiceForPay = null;
      });
      return;
    }

    if (result.isCanceled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.readTr(AppStrings.paymentCancelled)),
          backgroundColor: AppColors.subtitleTextColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (result.isNotConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.readTr(AppStrings.stripeNotConfigured)),
          backgroundColor: AppColors.orangeColor,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (result.isAlreadyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.readTr(AppStrings.invoiceAlreadyPaid)),
          backgroundColor: AppColors.emeraldGreenColor,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() {
        _selectedInvoiceForPay = null;
      });
      return;
    }

    if (result.isDeclined) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message != null && result.message!.isNotEmpty
                ? result.message!
                : ref.readTr(AppStrings.paymentDeclined),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (result.isUnsupportedPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.readTr(AppStrings.paymentUnsupportedPlatform)),
          backgroundColor: AppColors.orangeColor,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (result.isNetworkError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.readTr(AppStrings.paymentNetworkError)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Generic error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message != null && result.message!.isNotEmpty
              ? result.message!
              : ref.readTr(AppStrings.paymentFailed),
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

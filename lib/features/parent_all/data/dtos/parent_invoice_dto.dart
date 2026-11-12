import 'package:intl/intl.dart';

import '../../../../core/localization/localization_meta.dart';
import '../../../../core/service/language/language_provider.dart';
import '../../domain/models/parent_models.dart';

class ParentInvoiceDto {
  final String id;
  final String feeTitle;
  final String studentName;
  final double amount;
  final String currency;
  final String dueDate;
  final String status;
  final String? paidAt;
  final LocalizationMeta? localization;

  const ParentInvoiceDto({
    required this.id,
    required this.feeTitle,
    required this.studentName,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.localization,
  });

  factory ParentInvoiceDto.fromJson(Map<String, dynamic> json) {
    return ParentInvoiceDto(
      id: json['id'] as String? ?? '',
      feeTitle: json['feeTitle'] as String? ?? json['title'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
      dueDate: json['dueDate'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      paidAt: json['paidAt'] as String?,
      localization: LocalizationMeta.tryParse(json),
    );
  }

  static String _formatDate(DateTime dt, String pattern) {
    final locale = LanguageNotifier.activeLanguageCode;
    try {
      return DateFormat(pattern, locale).format(dt);
    } catch (_) {
      return DateFormat(pattern).format(dt);
    }
  }

  InvoiceModel toModel() {
    DateTime? dueDt = DateTime.tryParse(dueDate);
    DateTime? paidDt = paidAt != null ? DateTime.tryParse(paidAt!) : null;

    final monthYear = dueDt != null ? _formatDate(dueDt, 'MMMM yyyy') : '';
    final formattedDue =
        dueDt != null ? _formatDate(dueDt, 'd MMM yyyy') : dueDate;
    final isPaid = status.toUpperCase() == 'PAID';
    final formattedPaid =
        paidDt != null ? _formatDate(paidDt, 'd MMM yyyy') : null;
    final displayTitle = feeTitle;
    final displayConcept = studentName.isNotEmpty
        ? (displayTitle.isNotEmpty ? '$displayTitle ($studentName)' : studentName)
        : displayTitle;
    final recNum = isPaid
        ? 'REC-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}'
        : null;

    return InvoiceModel(
      id: id,
      concept: displayConcept,
      monthYear: monthYear,
      amount: amount,
      dueDate: formattedDue,
      isPaid: isPaid,
      paidDate: formattedPaid,
      receiptNumber: recNum,
      status: status,
      studentName: studentName,
      feeTitle: displayTitle,
      currency: currency,
      localization: localization,
    );
  }
}

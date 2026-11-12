import 'package:flutter/material.dart';
import '../../../../core/localization/localization_meta.dart';
import '../../helper/parent_enums.dart';

export '../../helper/parent_enums.dart';

// ===============================================================
// CHILD MODEL
// ===============================================================

class ChildModel {
  final String id;
  final String name;
  final String grade;
  final String room;
  final String imageUrl;
  final String parentTeacher;
  final double attendance;
  final int present;
  final int absent;
  final int late;
  final LocalizationMeta? localization;

  const ChildModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.room,
    required this.imageUrl,
    required this.parentTeacher,
    required this.attendance,
    required this.present,
    required this.absent,
    required this.late,
    this.localization,
  });

  ChildModel copyWith({
    String? id,
    String? name,
    String? grade,
    String? room,
    String? imageUrl,
    String? parentTeacher,
    double? attendance,
    int? present,
    int? absent,
    int? late,
    LocalizationMeta? localization,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      room: room ?? this.room,
      imageUrl: imageUrl ?? this.imageUrl,
      parentTeacher: parentTeacher ?? this.parentTeacher,
      attendance: attendance ?? this.attendance,
      present: present ?? this.present,
      absent: absent ?? this.absent,
      late: late ?? this.late,
      localization: localization ?? this.localization,
    );
  }

  String get classroom => room;
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'ST';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ===============================================================
// CLASS MODEL
// ===============================================================

class ClassModel {
  final String? id;
  final String subject;
  final String teacher;
  final String time;
  final String duration;
  final String room;
  final String building;
  final String category;
  final Color color;
  final LocalizationMeta? localization;

  const ClassModel({
    this.id,
    required this.subject,
    required this.teacher,
    required this.time,
    required this.duration,
    required this.room,
    required this.building,
    required this.category,
    required this.color,
    this.localization,
  });

  ClassModel copyWith({
    String? id,
    String? subject,
    String? teacher,
    String? time,
    String? duration,
    String? room,
    String? building,
    String? category,
    Color? color,
    LocalizationMeta? localization,
  }) {
    return ClassModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      room: room ?? this.room,
      building: building ?? this.building,
      category: category ?? this.category,
      color: color ?? this.color,
      localization: localization ?? this.localization,
    );
  }
}

// ===============================================================
// STUDENT MODEL
// ===============================================================

class StudentModel {
  final String name;
  final String grade;
  final String initials;

  const StudentModel({
    required this.name,
    required this.grade,
    required this.initials,
  });
}

// ===============================================================
// REPORT MODEL
// ===============================================================

class ReportModel {
  final String? id;
  final String dateLabel;
  final DateTime? date;
  final String subject;
  final String teacher;
  final String time;
  final String category;
  final String status;
  final String note;
  final String initials;
  final LocalizationMeta? localization;

  const ReportModel({
    this.id,
    required this.dateLabel,
    this.date,
    required this.subject,
    required this.teacher,
    required this.time,
    required this.category,
    required this.status,
    required this.note,
    required this.initials,
    this.localization,
  });
}

// ===============================================================
// HOMEWORK MODEL
// ===============================================================

enum HomeworkStatus { pending, completed }

class HomeworkModel {
  final String? id;
  final String subject;
  final String teacher;
  final String period;
  final String title;
  final String description;
  final HomeworkStatus status;
  final String deadline;
  final String time;
  final String sourceLocale;
  final String displayedLocale;
  final bool isTranslated;
  final String translationStatus;

  LocalizationMeta get localization => LocalizationMeta(
        sourceLocale: sourceLocale,
        displayedLocale: displayedLocale,
        isTranslated: isTranslated,
        translationStatus: translationStatus,
      );

  const HomeworkModel({
    this.id,
    required this.subject,
    required this.teacher,
    required this.period,
    required this.title,
    required this.description,
    required this.status,
    required this.deadline,
    required this.time,
    this.sourceLocale = 'en',
    this.displayedLocale = 'en',
    this.isTranslated = false,
    this.translationStatus = 'READY',
  });

  HomeworkModel copyWith({
    String? id,
    String? subject,
    String? teacher,
    String? period,
    String? title,
    String? description,
    HomeworkStatus? status,
    String? deadline,
    String? time,
    String? sourceLocale,
    String? displayedLocale,
    bool? isTranslated,
    String? translationStatus,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      period: period ?? this.period,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      time: time ?? this.time,
      sourceLocale: sourceLocale ?? this.sourceLocale,
      displayedLocale: displayedLocale ?? this.displayedLocale,
      isTranslated: isTranslated ?? this.isTranslated,
      translationStatus: translationStatus ?? this.translationStatus,
    );
  }
}

// ===============================================================
// ATTENDANCE RECORD MODEL
// ===============================================================

class AttendanceRecord {
  final String date;
  final String dayName;
  final AttendanceStatus status;
  final String checkInTime;
  final String? note;
  final LocalizationMeta? localization;

  const AttendanceRecord({
    required this.date,
    required this.dayName,
    required this.status,
    required this.checkInTime,
    this.note,
    this.localization,
  });
}

// ===============================================================
// INVOICE / PAYMENT MODEL
// ===============================================================

class InvoiceModel {
  final String id;
  final String concept;
  final String monthYear;
  final double amount;
  final String dueDate;
  final bool isPaid;
  final String? paidDate;
  final String? receiptNumber;
  final String? status;
  final String? studentName;
  final String? feeTitle;
  final String currency;
  final LocalizationMeta? localization;

  const InvoiceModel({
    required this.id,
    required this.concept,
    required this.monthYear,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.paidDate,
    this.receiptNumber,
    this.status,
    this.studentName,
    this.feeTitle,
    this.currency = 'EUR',
    this.localization,
  });

  InvoiceModel copyWith({
    String? id,
    String? concept,
    String? monthYear,
    double? amount,
    String? dueDate,
    bool? isPaid,
    String? paidDate,
    String? receiptNumber,
    String? status,
    String? studentName,
    String? feeTitle,
    String? currency,
    LocalizationMeta? localization,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      concept: concept ?? this.concept,
      monthYear: monthYear ?? this.monthYear,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      status: status ?? this.status,
      studentName: studentName ?? this.studentName,
      feeTitle: feeTitle ?? this.feeTitle,
      currency: currency ?? this.currency,
      localization: localization ?? this.localization,
    );
  }
}

// ===============================================================
// NOTIFICATION MODEL
// ===============================================================

class ParentNotificationModel {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final bool isRead;
  final String type;
  final LocalizationMeta? localization;

  const ParentNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.isRead = false,
    required this.type,
    this.localization,
  });

  ParentNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    bool? isRead,
    String? type,
    LocalizationMeta? localization,
  }) {
    return ParentNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      localization: localization ?? this.localization,
    );
  }
}

// ===============================================================
// CHAT MESSAGE MODEL
// ===============================================================

class ChatMessageModel {
  final String id;
  final String senderName;
  final String message;
  final String time;
  final bool isMe;

  const ChatMessageModel({
    required this.id,
    required this.senderName,
    required this.message,
    required this.time,
    required this.isMe,
  });
}

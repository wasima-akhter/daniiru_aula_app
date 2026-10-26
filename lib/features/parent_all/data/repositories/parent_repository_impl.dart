import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../share/widgets/paginator/paginator.dart';
import '../../domain/models/parent_models.dart';
import '../../domain/repositories/parent_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../datasources/parent_remote_data_source.dart';
import '../dtos/add_child_dto.dart';
import '../dtos/announcement_dto.dart';
import '../dtos/child_attendance_dto.dart';
import '../dtos/child_progress_dto.dart';
import '../dtos/child_schedule_dto.dart';
import '../dtos/child_teacher_dto.dart';
import '../dtos/conversation_dto.dart';
import '../dtos/parent_invoice_dto.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRemoteDataSourceImpl(client);
});

final parentRemoteDataSourceProvider = Provider<ParentRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return ParentRemoteDataSourceImpl(client);
});

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  final notificationRemote = ref.watch(notificationRemoteDataSourceProvider);
  final parentRemote = ref.watch(parentRemoteDataSourceProvider);
  return ParentRepositoryImpl(
    notificationRemoteDataSource: notificationRemote,
    parentRemoteDataSource: parentRemote,
  );
});

class ParentRepositoryImpl implements ParentRepository {
  final NotificationRemoteDataSource? notificationRemoteDataSource;
  final ParentRemoteDataSource? parentRemoteDataSource;

  ParentRepositoryImpl({
    this.notificationRemoteDataSource,
    this.parentRemoteDataSource,
  });

  List<ChildModel> _children = [];
  List<InvoiceModel> _invoices = [];
  List<ParentNotificationModel> _notifications = [];
  final List<ChatMessageModel> _messages = [];
  final Map<String, int> _attendancePercentages = {};

  @override
  Future<List<ChildModel>> getChildren() async {
    if (parentRemoteDataSource != null) {
      try {
        final dtos = await parentRemoteDataSource!.getChildren();
        _children = dtos.map((dto) => dto.toModel()).toList();
        return _children;
      } catch (e) {
        debugPrint('ParentRepositoryImpl getChildren error: $e');
      }
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return _children;
  }

  @override
  Future<ChildModel> getChildDetails(String id) async {
    final list = await getChildren();
    return list.firstWhere((c) => c.id == id, orElse: () => list.first);
  }

  @override
  Future<ChildModel> addChild(AddChildDto dto) async {
    if (parentRemoteDataSource != null) {
      try {
        final childDto = await parentRemoteDataSource!.addChild(dto);
        final model = childDto.toModel();
        _children.removeWhere((c) => c.id == model.id);
        _children.add(model);
        return model;
      } catch (e) {
        debugPrint('ParentRepositoryImpl addChild remote error: $e');
      }
    }
    final fallback = ChildModel(
      id: '#STU-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: dto.fullName,
      grade: dto.gradeLevel ?? 'Curso general',
      room: dto.enrollmentNumber ?? '',
      imageUrl: dto.avatarUrl ?? '',
      parentTeacher: '',
      attendance: 0.0,
      present: 0,
      absent: 0,
      late: 0,
    );
    _children.removeWhere((c) => c.id == fallback.id);
    _children.add(fallback);
    return fallback;
  }

  @override
  Future<List<ClassModel>> getTodayClasses({String? childId}) async {
    if (childId != null && parentRemoteDataSource != null) {
      try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final sessions = await parentRemoteDataSource!.getChildSchedule(
          childId,
          fromDate: startOfDay,
          toDate: endOfDay,
        );
        return sessions.map((s) => s.toClassModel()).toList();
      } catch (e) {
        debugPrint('ParentRepositoryImpl getTodayClasses error: $e');
        return const [];
      }
    }
    return const [];
  }

  @override
  Future<List<ClassModel>> getWeeklySchedule(int dayIndex, {String? childId}) async {
    if (childId != null && parentRemoteDataSource != null) {
      try {
        final sessions = await parentRemoteDataSource!.getChildSchedule(childId);
        return sessions.map((s) => s.toClassModel()).toList();
      } catch (e) {
        debugPrint('ParentRepositoryImpl getWeeklySchedule error: $e');
      }
    }
    return const [];
  }

  @override
  Future<List<ChildScheduleSessionDto>> getChildSchedule(
    String childId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (parentRemoteDataSource != null) {
      try {
        return await parentRemoteDataSource!.getChildSchedule(
          childId,
          fromDate: fromDate,
          toDate: toDate,
        );
      } catch (e) {
        debugPrint('ParentRepositoryImpl getChildSchedule error: $e');
      }
    }
    return const [];
  }

  @override
  Future<List<ChildTeacherDto>> getChildTeachers(String childId) async {
    if (parentRemoteDataSource != null) {
      try {
        return await parentRemoteDataSource!.getChildTeachers(childId);
      } catch (e) {
        debugPrint('ParentRepositoryImpl getChildTeachers error: $e');
      }
    }
    return const [];
  }

  @override
  Future<ChildProgressDto> getChildProgress(String childId) async {
    if (parentRemoteDataSource != null) {
      try {
        final progress = await parentRemoteDataSource!.getChildProgress(childId);
        _attendancePercentages[childId] = progress.attendancePercentage.toInt();
        return progress;
      } catch (e) {
        debugPrint('ParentRepositoryImpl getChildProgress error: $e');
      }
    }
    return const ChildProgressDto(
      attendancePercentage: 0,
      homeworkCompletionPercentage: 0,
      subjects: [],
    );
  }

  @override
  Future<PaginatedResult<ReportModel>> getReports({
    int page = 1,
    int limit = 20,
  }) async {
    if (_children.isNotEmpty) {
      return getChildReports(_children.first.id, page: page, limit: limit);
    }
    return const PaginatedResult<ReportModel>(data: [], meta: null);
  }

  @override
  Future<PaginatedResult<ReportModel>> getChildReports(
    String childId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (parentRemoteDataSource != null) {
      try {
        final res = await parentRemoteDataSource!.getChildReports(
          childId,
          page: page,
          limit: limit,
        );
        return PaginatedResult<ReportModel>(
          data: res.data.map((d) => d.toModel()).toList(),
          meta: res.meta,
        );
      } catch (e) {
        debugPrint('ParentRepositoryImpl getChildReports error: $e');
      }
    }
    return const PaginatedResult<ReportModel>(data: [], meta: null);
  }

  @override
  Future<PaginatedResult<HomeworkModel>> getHomeworkList({
    int page = 1,
    int limit = 20,
  }) async {
    if (_children.isNotEmpty) {
      return getChildHomework(_children.first.id, page: page, limit: limit);
    }
    return const PaginatedResult<HomeworkModel>(data: [], meta: null);
  }

  @override
  Future<PaginatedResult<HomeworkModel>> getChildHomework(
    String childId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (parentRemoteDataSource != null) {
      try {
        final res = await parentRemoteDataSource!.getChildHomework(
          childId,
          page: page,
          limit: limit,
        );
        return PaginatedResult<HomeworkModel>(
          data: res.data.map((d) => d.toModel()).toList(),
          meta: res.meta,
        );
      } catch (e) {
        debugPrint('ParentRepositoryImpl getChildHomework error: $e');
      }
    }
    return const PaginatedResult<HomeworkModel>(data: [], meta: null);
  }

  @override
  Future<(ChildAttendanceMetaDto?, List<AttendanceRecord>)> getAttendanceHistory(
    String childId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (parentRemoteDataSource != null) {
      try {
        final (meta, dtos) = await parentRemoteDataSource!.getChildAttendance(
          childId,
          page: page,
          limit: limit,
        );
        if (meta != null) {
          _attendancePercentages[childId] = meta.percentage;
        }
        return (meta, dtos.map((d) => d.toRecord()).toList());
      } catch (e) {
        debugPrint('ParentRepositoryImpl getAttendanceHistory error: $e');
      }
    }
    return (null, const <AttendanceRecord>[]);
  }

  @override
  Future<int> getChildAttendancePercentage(String childId) async {
    if (_attendancePercentages.containsKey(childId)) {
      return _attendancePercentages[childId]!;
    }
    return 0;
  }

  @override
  Future<PaginatedResult<InvoiceModel>> getInvoices({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (parentRemoteDataSource != null) {
      try {
        final res = await parentRemoteDataSource!.getInvoices(
          status: status,
          page: page,
          limit: limit,
        );
        final models = res.data.map((d) => d.toModel()).toList();
        if (page == 1) {
          _invoices = models;
        }
        return PaginatedResult<InvoiceModel>(
          data: models,
          meta: res.meta,
        );
      } catch (e) {
        debugPrint('ParentRepositoryImpl getInvoices error: $e');
      }
    }
    return PaginatedResult<InvoiceModel>(data: _invoices, meta: null);
  }

  @override
  Future<PaginatedResult<ParentInvoiceDto>> getRawInvoices({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (parentRemoteDataSource != null) {
      return parentRemoteDataSource!.getInvoices(
        status: status,
        page: page,
        limit: limit,
      );
    }
    return const PaginatedResult<ParentInvoiceDto>(data: [], meta: null);
  }

  @override
  Future<String?> payInvoice(String invoiceId, [String? paymentMethod]) async {
    if (parentRemoteDataSource != null) {
      return await parentRemoteDataSource!.payInvoice(invoiceId);
    }

    // Mock fallback when testing without remote data source
    _invoices = _invoices.map((inv) {
      if (inv.id == invoiceId) {
        return inv.copyWith(
          isPaid: true,
          paidDate: 'Hoy',
          receiptNumber: 'REC-${DateTime.now().millisecondsSinceEpoch % 10000}',
        );
      }
      return inv;
    }).toList();

    return 'pi_mock_secret_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<PaginatedResult<ParentNotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    if (notificationRemoteDataSource != null) {
      try {
        final res = await notificationRemoteDataSource!.getAllNotifications(
          page: page,
          limit: limit,
        );
        final models = res.data.map((d) => d.toModel()).toList();
        if (page == 1) {
          _notifications = models;
        }
        return PaginatedResult<ParentNotificationModel>(
          data: models,
          meta: res.meta,
        );
      } catch (e) {
        debugPrint('ParentRepositoryImpl getNotifications error: $e');
      }
    }
    return PaginatedResult<ParentNotificationModel>(
      data: _notifications,
      meta: null,
    );
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    if (notificationRemoteDataSource != null) {
      try {
        return await notificationRemoteDataSource!.getUnreadCount();
      } catch (_) {}
    }
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markNotificationAsRead(String id) async {
    _notifications = _notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    if (notificationRemoteDataSource != null) {
      try {
        await notificationRemoteDataSource!.markAsRead(id);
      } catch (_) {}
    }
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();

    if (notificationRemoteDataSource != null) {
      try {
        await notificationRemoteDataSource!.markAllAsRead();
      } catch (_) {}
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _messages;
  }

  @override
  Future<void> sendMessage(String teacherId, String message) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _messages.add(
      ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderName: 'Eleanor Vance',
        message: message,
        time:
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        isMe: true,
      ),
    );
  }

  @override
  Future<List<ConversationDto>> getConversations() async {
    if (parentRemoteDataSource != null) {
      try {
        return await parentRemoteDataSource!.getConversations();
      } catch (_) {}
    }
    return const [];
  }

  @override
  Future<ChatMessageDto> sendConversationMessage(
    String conversationId,
    String body,
  ) async {
    if (parentRemoteDataSource != null) {
      return parentRemoteDataSource!.sendConversationMessage(
        conversationId,
        body,
      );
    }
    return ChatMessageDto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: 'me',
      body: body,
      sentAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<PaginatedResult<AnnouncementDto>> getAnnouncements({
    int page = 1,
    int limit = 10,
  }) async {
    if (parentRemoteDataSource != null) {
      try {
        return await parentRemoteDataSource!.getAnnouncements(
          page: page,
          limit: limit,
        );
      } catch (_) {}
    }
    return const PaginatedResult<AnnouncementDto>(data: [], meta: null);
  }

  @override
  Future<ConversationDto> createConversation(String targetUserId) async {
    if (parentRemoteDataSource != null) {
      return await parentRemoteDataSource!.createConversation(targetUserId);
    }
    return ConversationDto(
      id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      type: 'PARENT_ADMIN',
      unreadCount: 0,
    );
  }

  @override
  Future<List<ChatMessageDto>> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (parentRemoteDataSource != null) {
      try {
        return await parentRemoteDataSource!.getConversationMessages(
          conversationId,
          page: page,
          limit: limit,
        );
      } catch (_) {}
    }
    return const [];
  }
}

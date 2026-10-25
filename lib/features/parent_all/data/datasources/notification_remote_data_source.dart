import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../share/model/pagination_meta_model.dart';
import '../../../share/widgets/paginator/paginator.dart';
import '../dtos/notification_dto.dart';

abstract class NotificationRemoteDataSource {
  Future<PaginatedResult<NotificationDto>> getAllNotifications({int page = 1, int limit = 20});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _client;

  NotificationRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResult<NotificationDto>> getAllNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      PaginationMeta? meta;
      List<NotificationDto> list = [];

      if (data is Map<String, dynamic>) {
        if (data['meta'] is Map<String, dynamic>) {
          meta = PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>);
        }
        final listData = data['data'];
        if (listData is List) {
          list = listData
              .whereType<Map<String, dynamic>>()
              .map(NotificationDto.fromJson)
              .toList();
        }
      } else if (data is List) {
        list = data
            .whereType<Map<String, dynamic>>()
            .map(NotificationDto.fromJson)
            .toList();
      }

      return PaginatedResult<NotificationDto>(data: list, meta: meta);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch notifications: $e', statusCode: 500);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _client.get(ApiConstants.notificationsUnreadCount);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          return (nested['count'] as num?)?.toInt() ??
              (nested['unreadCount'] as num?)?.toInt() ??
              0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _client.patch(ApiConstants.notificationRead(id));
    } catch (e) {
      // Remote call completed with best-effort
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _client.patch(ApiConstants.notificationsReadAll);
    } catch (e) {
      // Remote call completed with best-effort
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../parent_all/data/dtos/conversation_dto.dart';

abstract class ChatRepository {
  Future<List<ConversationDto>> getConversations();
  Future<ConversationDto> createConversation({String? targetUserId});
  Future<List<ChatMessageDto>> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  });
  Future<ChatMessageDto> sendConversationMessage(
    String conversationId,
    String body,
  );
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatRepositoryImpl(client);
});

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _client;

  ChatRepositoryImpl(this._client);

  @override
  Future<List<ConversationDto>> getConversations() async {
    try {
      final response = await _client.get(ApiConstants.conversations);
      final data = response.data;
      List<ConversationDto> list = [];
      if (data is Map<String, dynamic>) {
        final raw = data['data'];
        if (raw is List) {
          list = raw
              .whereType<Map<String, dynamic>>()
              .map(ConversationDto.fromJson)
              .toList();
        }
      } else if (data is List) {
        list = data
            .whereType<Map<String, dynamic>>()
            .map(ConversationDto.fromJson)
            .toList();
      }

      // Filter strictly to admin conversations (Parent <-> Admin, Teacher <-> Admin)
      final adminConversations = list.where((c) {
        final role = (c.role ?? '').toUpperCase();
        final type = (c.type ?? '').toUpperCase();
        final name = (c.displayName).toUpperCase();
        return role == 'ADMIN' ||
            type.contains('ADMIN') ||
            name.contains('ADMIN') ||
            role.isEmpty; // if unspecified, keep as general thread
      }).toList();

      return adminConversations.isNotEmpty ? adminConversations : list;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch conversations: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ConversationDto> createConversation({String? targetUserId}) async {
    try {
      // Backend guideline:
      // When initiating as Parent or Teacher to chat with Administration, send empty body: {}
      // The backend automatically looks up or creates the central PARENT_ADMIN or TEACHER_ADMIN conversation.
      final payload = (targetUserId != null && targetUserId.isNotEmpty)
          ? <String, dynamic>{'targetUserId': targetUserId}
          : <String, dynamic>{};

      final response = await _client.post(
        ApiConstants.conversations,
        data: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final convData = data['data'];
        if (convData is Map<String, dynamic>) {
          return ConversationDto.fromJson(convData);
        } else if (convData is List && convData.isNotEmpty) {
          final first = convData.first;
          if (first is Map<String, dynamic>) {
            return ConversationDto.fromJson(first);
          }
        } else if (data['id'] != null) {
          return ConversationDto.fromJson(data);
        }
      }
      throw ApiException(
        message: 'Invalid response format for create conversation',
        statusCode: 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to create conversation: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ChatMessageDto>> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.conversationMessages(conversationId),
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(ChatMessageDto.fromJson)
              .toList();
        }
      } else if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ChatMessageDto.fromJson)
            .toList();
      }
      return const [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch messages: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ChatMessageDto> sendConversationMessage(
    String conversationId,
    String body,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.conversationMessages(conversationId),
        data: {'body': body},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final msgData = data['data'];
        if (msgData is Map<String, dynamic>) {
          return ChatMessageDto.fromJson(msgData);
        }
      }
      throw ApiException(
        message: 'Invalid response format for send message',
        statusCode: 500,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to send message: $e', statusCode: 500);
    }
  }
}

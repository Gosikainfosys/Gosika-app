import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/chat_model.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  /// GET /customer/conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiClient.dio.get('/customer/conversations');
      final data = response.data['data'] as List? ?? [];
      return data.map((item) => Conversation.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// GET /customer/conversations/{id}
  Future<Conversation> getConversationDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/customer/conversations/$id');
      final data = response.data['data'] ?? response.data;
      return Conversation.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// POST /customer/conversations (idempotent support or store chat creation)
  Future<Conversation> getOrCreateConversation({String type = 'support', String? storeId}) async {
    try {
      final response = await _apiClient.dio.post('/customer/conversations', data: {
        'type': type,
        if (type == 'support') 'subject': 'GOSIKA Support',
        if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      });
      final data = response.data['data'] ?? response.data;
      return Conversation.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// POST /customer/conversations/{id}/messages
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String message,
    required String clientUuid,
    List<File>? imageFiles,
  }) async {
    try {
      dynamic postData;
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final formData = FormData();
        if (message.isNotEmpty) {
          formData.fields.add(MapEntry('message', message));
        }
        formData.fields.add(MapEntry('client_uuid', clientUuid));
        for (var file in imageFiles) {
          final filename = file.path.split('/').last;
          formData.files.add(MapEntry(
            'images[]',
            await MultipartFile.fromFile(file.path, filename: filename),
          ));
        }
        postData = formData;
      } else {
        postData = {
          'message': message,
          'client_uuid': clientUuid,
        };
      }

      final response = await _apiClient.dio.post(
        '/customer/conversations/$conversationId/messages',
        data: postData,
      );

      final data = response.data['data']?['message'] ?? response.data['data'] ?? response.data;
      return ChatMessage.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// POST /customer/conversations/{id}/read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiClient.dio.post('/customer/conversations/$conversationId/read');
    } catch (e) {
      // Non-blocking
    }
  }
}

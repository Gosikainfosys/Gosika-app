import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ApiClient());
});

final conversationsListProvider = StateNotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>((ref) {
  return ConversationsNotifier(ref.watch(chatServiceProvider), ref);
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final ChatService _service;
  final Ref _ref;

  ConversationsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadConversations();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated && next.isAuthenticated) {
        loadConversations();
      }
    });
  }

  Future<void> loadConversations() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final list = await _service.getConversations();
      state = AsyncValue.data(list);
    } catch (e, st) {
      final isAuthenticated = _ref.read(authProvider).isAuthenticated;
      final errorMsg = ApiClient.parseError(e).toLowerCase();
      if (!isAuthenticated || errorMsg.contains('unauthenticated') || errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
        state = const AsyncValue.data([]);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async {
    try {
      final isAuthenticated = _ref.read(authProvider).isAuthenticated;
      if (!isAuthenticated) {
        state = const AsyncValue.data([]);
        return;
      }
      final list = await _service.getConversations();
      state = AsyncValue.data(list);
    } catch (e) {
      // Keep existing state
    }
  }

  Future<Conversation> getOrCreateSupport() async {
    final supportConv = await _service.getOrCreateConversation(type: 'support');
    refresh();
    return supportConv;
  }

  Future<Conversation> getOrCreateStoreChat(String storeId) async {
    final conv = await _service.getOrCreateConversation(type: 'store', storeId: storeId);
    refresh();
    return conv;
  }
}

final conversationDetailProvider = StateNotifierProvider.family<ConversationDetailNotifier, AsyncValue<Conversation>, String>((ref, id) {
  final service = ref.watch(chatServiceProvider);
  return ConversationDetailNotifier(service, id, ref);
});

class ConversationDetailNotifier extends StateNotifier<AsyncValue<Conversation>> {
  final ChatService _service;
  final String conversationId;
  final Ref _ref;
  Timer? _pollingTimer;

  ConversationDetailNotifier(this._service, this.conversationId, this._ref)
      : super(const AsyncValue.loading()) {
    loadDetail();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollDetail();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  Future<void> loadDetail() async {
    try {
      state = const AsyncValue.loading();
      final conv = await _service.getConversationDetail(conversationId);
      state = AsyncValue.data(conv);
      _service.markAsRead(conversationId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _pollDetail() async {
    try {
      final conv = await _service.getConversationDetail(conversationId);
      final current = state.value;
      if (current == null) {
        state = AsyncValue.data(conv);
        return;
      }

      final pendingMessages = current.messages.where((m) => m.isPending).toList();
      final fetchedMessages = List<ChatMessage>.from(conv.messages);

      for (var pending in pendingMessages) {
        final exists = fetchedMessages.any((m) =>
            m.clientUuid == pending.clientUuid || (m.id.isNotEmpty && m.id == pending.id));
        if (!exists) {
          fetchedMessages.add(pending);
        }
      }

      fetchedMessages.sort((a, b) => a.cursor.compareTo(b.cursor));
      state = AsyncValue.data(conv.copyWith(messages: fetchedMessages));
    } catch (e) {
      // Ignore polling errors silently
    }
  }

  Future<void> sendMessage({
    required String text,
    List<File>? imageFiles,
    required String currentUserId,
  }) async {
    final currentConv = state.value;
    if (currentConv == null) return;

    final clientUuid = const Uuid().v4();
    final tempPendingMsg = ChatMessage(
      id: clientUuid,
      cursor: (currentConv.messages.isNotEmpty ? currentConv.messages.last.cursor + 1 : 1),
      message: text,
      sender: ChatSender(id: currentUserId, name: 'You', type: 'customer'),
      images: imageFiles != null ? imageFiles.map((f) => f.path).toList() : [],
      clientUuid: clientUuid,
      createdAt: DateTime.now(),
      isPending: true,
    );

    final updatedMessages = List<ChatMessage>.from(currentConv.messages)..add(tempPendingMsg);
    state = AsyncValue.data(currentConv.copyWith(messages: updatedMessages));

    try {
      final sentMsg = await _service.sendMessage(
        conversationId: conversationId,
        message: text,
        clientUuid: clientUuid,
        imageFiles: imageFiles,
      );

      final confirmedConv = state.value;
      if (confirmedConv != null) {
        final finalMessages = confirmedConv.messages.map((m) {
          if (m.clientUuid == clientUuid || m.id == clientUuid) {
            return sentMsg;
          }
          return m;
        }).toList();

        finalMessages.sort((a, b) => a.cursor.compareTo(b.cursor));
        state = AsyncValue.data(confirmedConv.copyWith(messages: finalMessages));
      }

      _ref.read(conversationsListProvider.notifier).refresh();
    } catch (e) {
      // Rollback on error
      final failedConv = state.value;
      if (failedConv != null) {
        final rolledBack = failedConv.messages.where((m) => m.clientUuid != clientUuid).toList();
        state = AsyncValue.data(failedConv.copyWith(messages: rolledBack));
      }
      rethrow;
    }
  }
}

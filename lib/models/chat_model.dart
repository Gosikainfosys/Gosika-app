class ChatSender {
  final String id;
  final String name;
  final String? avatar;
  final String? type;

  ChatSender({
    required this.id,
    required this.name,
    this.avatar,
    this.type,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    return ChatSender(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['first_name']?.toString() ?? 'Support',
      avatar: json['avatar']?.toString(),
      type: json['type']?.toString(),
    );
  }
}

class ChatMessage {
  final String id;
  final int cursor;
  final String message;
  final ChatSender? sender;
  final List<String> images;
  final String? clientUuid;
  final DateTime? createdAt;
  final bool isPending;

  ChatMessage({
    required this.id,
    required this.cursor,
    required this.message,
    this.sender,
    this.images = const [],
    this.clientUuid,
    this.createdAt,
    this.isPending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List? ?? [];
    
    String msgText = '';
    final rawMsg = json['message'] ?? json['body'] ?? json['text'] ?? json['content'];
    if (rawMsg is String) {
      msgText = rawMsg;
    } else if (rawMsg is Map) {
      msgText = rawMsg['message']?.toString() ??
          rawMsg['body']?.toString() ??
          rawMsg['text']?.toString() ??
          rawMsg['content']?.toString() ??
          '';
    } else if (rawMsg != null) {
      msgText = rawMsg.toString();
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      cursor: json['cursor'] is num ? (json['cursor'] as num).toInt() : 0,
      message: msgText,
      sender: json['sender'] != null ? ChatSender.fromJson(json['sender']) : null,
      images: rawImages.map((e) => e.toString()).toList(),
      clientUuid: json['client_uuid']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      isPending: false,
    );
  }
}

class Conversation {
  final String id;
  final String title;
  final String? type;
  final String? status;
  final int unreadCount;
  final ChatMessage? lastMessage;
  final List<ChatMessage> messages;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  Conversation({
    required this.id,
    required this.title,
    this.type,
    this.status,
    this.unreadCount = 0,
    this.lastMessage,
    this.messages = const [],
    this.updatedAt,
    this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List? ?? [];
    final msgList = rawMessages.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();

    msgList.sort((a, b) => a.cursor.compareTo(b.cursor));

    ChatMessage? lastMsg;
    if (json['last_message'] != null) {
      lastMsg = ChatMessage.fromJson(json['last_message']);
    } else if (msgList.isNotEmpty) {
      lastMsg = msgList.last;
    }

    return Conversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Support Chat',
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      unreadCount: json['unread_count'] is num ? (json['unread_count'] as num).toInt() : 0,
      lastMessage: lastMsg,
      messages: msgList,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Conversation copyWith({
    String? id,
    String? title,
    String? type,
    String? status,
    int? unreadCount,
    ChatMessage? lastMessage,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationItem {
  final String id;
  final String? type;
  final String title;
  final String message;
  final String? link;
  final DateTime? readAt;
  final DateTime? createdAt;

  NotificationItem({
    required this.id,
    this.type,
    required this.title,
    required this.message,
    this.link,
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString(),
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      link: json['link']?.toString(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class NotificationResponse {
  final List<NotificationItem> notifications;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    List rawList = [];
    if (json['data'] is List) {
      rawList = json['data'];
    } else if (json['notifications'] is List) {
      rawList = json['notifications'];
    }

    final list = rawList
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();

    int count = 0;
    if (json['meta'] != null && json['meta']['unread_count'] != null) {
      count = (json['meta']['unread_count'] as num).toInt();
    } else if (json['unread_count'] != null) {
      count = (json['unread_count'] as num).toInt();
    } else {
      count = list.where((n) => !n.isRead).length;
    }

    return NotificationResponse(
      notifications: list,
      unreadCount: count,
    );
  }
}

/// Data model for student notification items in Phase 8.
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String date;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    this.isRead = false,
  });

  /// Factory constructor to deserialize JSON payload from Apps Script.
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['notificationId'] ?? json['id'] ?? '').toString().trim(),
      userId: (json['userId'] ?? json['userid'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString().trim(),
      message: (json['message'] ?? '').toString().trim(),
      type: (json['type'] ?? 'general').toString().trim(),
      date: (json['date'] ?? '').toString().trim(),
      isRead: json['isRead'] == true ||
          (json['isRead']?.toString().toLowerCase() == 'true') ||
          (json['status']?.toString().toLowerCase() == 'read'),
    );
  }

  /// Serializes NotificationItem into JSON map format.
  Map<String, dynamic> toJson() {
    return {
      'notificationId': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'date': date,
      'isRead': isRead,
    };
  }

  /// Creates a copy of this NotificationItem with optional updated fields.
  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? date,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
    );
  }
}

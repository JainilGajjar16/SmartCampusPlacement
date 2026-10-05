/// Data model representing a system broadcast announcement.
class SystemBroadcastItem {
  final String broadcastId;
  final String title;
  final String message;
  final String audience; // 'all', 'student', 'company'
  final String createdBy;
  final String date;
  final String status;

  const SystemBroadcastItem({
    required this.broadcastId,
    required this.title,
    required this.message,
    required this.audience,
    this.createdBy = 'Admin',
    this.date = '',
    this.status = 'Active',
  });

  factory SystemBroadcastItem.fromJson(Map<String, dynamic> json) {
    return SystemBroadcastItem(
      broadcastId:
          json['broadcastId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      audience: json['audience']?.toString() ??
          json['targetAudience']?.toString() ??
          'all',
      createdBy: json['createdBy']?.toString() ??
          json['author']?.toString() ??
          'Admin',
      date: json['date']?.toString() ??
          json['dateStr']?.toString() ??
          json['timestamp']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'broadcastId': broadcastId,
      'title': title,
      'message': message,
      'audience': audience,
      'createdBy': createdBy,
      'date': date,
      'status': status,
    };
  }

  String get audienceLabel {
    switch (audience.toLowerCase()) {
      case 'student':
      case 'students':
        return 'Students Only';
      case 'company':
      case 'companies':
      case 'recruiter':
      case 'recruiters':
        return 'Recruiters Only';
      case 'all':
      default:
        return 'All Campus Users';
    }
  }
}

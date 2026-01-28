class NotificationModel {
  final String id;
  final String type;
  final String notifiableType;
  final int notifiableId;
  final NotificationDataModel data;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.notifiableType,
    required this.notifiableId,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      notifiableType: json['notifiable_type'],
      notifiableId: json['notifiable_id'],
      data: NotificationDataModel.fromJson(json['data'] ?? {}),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationDataModel {
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> extraData;
  final DateTime? createdAt;

  NotificationDataModel({
    required this.title,
    required this.message,
    required this.type,
    required this.extraData,
    this.createdAt,
  });

  factory NotificationDataModel.fromJson(Map<String, dynamic> json) {
    return NotificationDataModel(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      extraData: json['data'] ?? {},
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }
}

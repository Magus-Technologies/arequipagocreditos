import 'dart:convert';

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
    // data puede venir como Map o como String JSON
    dynamic rawData = json['data'];
    Map<String, dynamic> dataMap;
    if (rawData is String) {
      dataMap = jsonDecode(rawData) as Map<String, dynamic>;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    } else {
      dataMap = {};
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      notifiableType: json['notifiable_type']?.toString() ?? '',
      notifiableId: json['notifiable_id'] is int
          ? json['notifiable_id']
          : int.tryParse(json['notifiable_id']?.toString() ?? '0') ?? 0,
      data: NotificationDataModel.fromJson(dataMap),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? notifiableType,
    int? notifiableId,
    NotificationDataModel? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      notifiableType: notifiableType ?? this.notifiableType,
      notifiableId: notifiableId ?? this.notifiableId,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationDataModel {
  final String title;
  final String message;
  final String type;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String? link;
  final Map<String, dynamic> extraData;
  final DateTime? createdAt;

  NotificationDataModel({
    required this.title,
    required this.message,
    required this.type,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.link,
    required this.extraData,
    this.createdAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;
  bool get hasLink => link != null && link!.isNotEmpty;

  factory NotificationDataModel.fromJson(Map<String, dynamic> json) {
    return NotificationDataModel(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      imageUrl: json['image_url'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      link: json['link'],
      extraData: json['data'] ?? {},
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }
}

class NotificationDto {
  final int id;
  final int? userId;
  final String notificationType;
  final String title;
  final String message;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationDto({
    required this.id,
    this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return NotificationDto(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int?,
      notificationType: json['notificationType'] as String? ?? 'GENERAL',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      referenceId: json['referenceId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      readAt: parseNullableDate(json['readAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      if (userId != null) 'userId': userId,
      'notificationType': notificationType,
      'title': title,
      'message': message,
      if (referenceId != null) 'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
    };
  }

  NotificationDto copyWith({
    int? id,
    int? userId,
    String? notificationType,
    String? title,
    String? message,
    int? referenceId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

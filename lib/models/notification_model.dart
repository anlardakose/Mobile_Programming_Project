enum NotificationType {
  health,
  safety,
  environment,
  lostFound,
  technical,
}

enum NotificationStatus {
  open,
  underReview,
  resolved,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final NotificationStatus status;
  final String userId;
  final String? userName;
  final double latitude;
  final double longitude;
  final List<String>? photoUrls;
  final List<String>? followedBy;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.userId,
    this.userName,
    required this.latitude,
    required this.longitude,
    this.photoUrls,
    this.followedBy,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.technical,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => NotificationStatus.open,
      ),
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoUrls: json['photoUrls'] != null
          ? List<String>.from(json['photoUrls'] as List)
          : null,
      followedBy: json['followedBy'] != null
          ? List<String>.from(json['followedBy'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString(),
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrls': photoUrls,
      'followedBy': followedBy,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? description,
    DateTime? createdAt,
    NotificationStatus? status,
    String? userId,
    String? userName,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
    List<String>? followedBy,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrls: photoUrls ?? this.photoUrls,
      followedBy: followedBy ?? this.followedBy,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.health:
        return 'Health';
      case NotificationType.safety:
        return 'Safety';
      case NotificationType.environment:
        return 'Environment';
      case NotificationType.lostFound:
        return 'Lost & Found';
      case NotificationType.technical:
        return 'Technical';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case NotificationStatus.open:
        return 'Open';
      case NotificationStatus.underReview:
        return 'Under Review';
      case NotificationStatus.resolved:
        return 'Resolved';
    }
  }
}



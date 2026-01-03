import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';

/// Notification types in the app
enum NotificationType {
  orderUpdate,
  promotion,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.orderUpdate:
        return 'Order Update';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.system:
        return 'System';
    }
  }
}

/// App notification model
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;
  final UserType? targetUserType;
  final bool shouldPush;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
    this.targetUserType,
    this.shouldPush = true,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    body,
    type,
    orderId,
    isRead,
    createdAt,
    targetUserType,
    shouldPush,
  ];

  /// Returns a human-readable time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
  }

  /// Creates a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? orderId,
    bool? isRead,
    DateTime? createdAt,
    UserType? targetUserType,
    bool? shouldPush,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      targetUserType: targetUserType ?? this.targetUserType,
      shouldPush: shouldPush ?? this.shouldPush,
    );
  }

  /// Creates an AppNotification from Firestore document data
  factory AppNotification.fromJson(Map<String, dynamic> json, String id) {
    return AppNotification(
      id: id,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      orderId: json['orderId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      targetUserType: json['targetUserType'] != null
          ? UserType.values.firstWhere(
              (e) => e.name == json['targetUserType'],
              orElse: () => UserType.customer,
            )
          : null,
      shouldPush: json['shouldPush'] as bool? ?? true,
    );
  }

  /// Converts AppNotification to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': createdAt,
      'targetUserType': targetUserType?.name,
      'shouldPush': shouldPush,
    };
  }
}

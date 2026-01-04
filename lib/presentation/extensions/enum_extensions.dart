import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/models/notification/notification.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';

/// Extension for OrderStatus to provide UI-specific data.
extension OrderStatusUI on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Extension for NotificationType to provide UI-specific data.
extension NotificationTypeUI on NotificationType {
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

/// Extension for UserType to provide UI-specific data.
extension UserTypeUI on UserType {
  String get displayName {
    switch (this) {
      case UserType.farmer:
        return 'Farmer Account';
      case UserType.customer:
        return 'Customer Account';
    }
  }
}

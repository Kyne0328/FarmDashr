/// Order status enumeration.
/// Follows Open/Closed Principle - can add new statuses without modifying existing code.
enum OrderStatus {
  ready,
  pending,
  completed;

  /// Display name for the status
  String get displayName {
    switch (this) {
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
    }
  }
}

/// Order data model.
/// Follows Single Responsibility Principle - only handles order data.
class Order {
  final String id;
  final String customerName;
  final int itemCount;
  final DateTime createdAt;
  final OrderStatus status;
  final double amount;
  final List<OrderItem>? items;

  const Order({
    required this.id,
    required this.customerName,
    required this.itemCount,
    required this.createdAt,
    required this.status,
    required this.amount,
    this.items,
  });

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

  /// Returns formatted amount string
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  /// Creates a copy with updated fields
  Order copyWith({
    String? id,
    String? customerName,
    int? itemCount,
    DateTime? createdAt,
    OrderStatus? status,
    double? amount,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      items: items ?? this.items,
    );
  }

  /// Sample data for development/testing
  static List<Order> get sampleOrders => [
    Order(
      id: '1',
      customerName: 'Sarah Johnson',
      itemCount: 3,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      status: OrderStatus.ready,
      amount: 45.50,
    ),
    Order(
      id: '2',
      customerName: 'Mike Chen',
      itemCount: 5,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      status: OrderStatus.pending,
      amount: 78.25,
    ),
    Order(
      id: '3',
      customerName: 'Emily Davis',
      itemCount: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: OrderStatus.completed,
      amount: 32.00,
    ),
  ];
}

/// Order item model
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
}

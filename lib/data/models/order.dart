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
  String get formattedAmount => '₱${amount.toStringAsFixed(2)}';

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

  /// Creates an Order from Firestore document data
  factory Order.fromJson(Map<String, dynamic> json, String id) {
    return Order(
      id: id,
      customerName: json['customerName'] as String? ?? '',
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts Order to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'itemCount': itemCount,
      'createdAt': createdAt,
      'status': status.name,
      'amount': amount,
      'items': items?.map((item) => item.toJson()).toList(),
    };
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
  String get formattedPrice => '₱${price.toStringAsFixed(2)}';
  String get formattedTotal => '₱${total.toStringAsFixed(2)}';

  /// Creates an OrderItem from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts OrderItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }
}

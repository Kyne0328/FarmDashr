import 'package:equatable/equatable.dart';

enum OrderStatus {
  ready,
  pending,
  completed,
  cancelled;

  /// Display name for the status
  String get displayName {
    switch (this) {
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

/// Order data model.

class Order extends Equatable {
  final String id;
  final String customerId; // Added for user linking
  final String customerName;
  final String farmerId; // Added for vendor linking
  final String farmerName; // Added for vendor linking
  final int itemCount;
  final DateTime createdAt;
  final OrderStatus status;
  final double amount;
  final List<OrderItem>? items;
  final String? pickupLocation; // Added
  final String? pickupDate; // Added
  final String? pickupTime; // Added
  final String? specialInstructions; // Added

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.farmerId,
    required this.farmerName,
    required this.itemCount,
    required this.createdAt,
    required this.status,
    required this.amount,
    this.items,
    this.pickupLocation,
    this.pickupDate,
    this.pickupTime,
    this.specialInstructions,
  });

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    farmerId,
    farmerName,
    itemCount,
    createdAt,
    status,
    amount,
    items,
    pickupLocation,
    pickupDate,
    pickupTime,
    specialInstructions,
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

  /// Returns formatted amount string
  String get formattedAmount => '₱${amount.toStringAsFixed(2)}';

  /// Creates a copy with updated fields
  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? farmerId,
    String? farmerName,
    int? itemCount,
    DateTime? createdAt,
    OrderStatus? status,
    double? amount,
    List<OrderItem>? items,
    String? pickupLocation,
    String? pickupDate,
    String? pickupTime,
    String? specialInstructions,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      items: items ?? this.items,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  /// Creates an Order from Firestore document data
  factory Order.fromJson(Map<String, dynamic> json, String id) {
    return Order(
      id: id,
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      farmerId: json['farmerId'] as String? ?? '',
      farmerName: json['farmerName'] as String? ?? '',
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
      pickupLocation: json['pickupLocation'] as String?,
      pickupDate: json['pickupDate'] as String?,
      pickupTime: json['pickupTime'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  /// Converts Order to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'itemCount': itemCount,
      'createdAt': createdAt,
      'status': status.name,
      'amount': amount,
      'items': items?.map((item) => item.toJson()).toList(),
      'pickupLocation': pickupLocation,
      'pickupDate': pickupDate,
      'pickupTime': pickupTime,
      'specialInstructions': specialInstructions,
    };
  }
}

/// Order item model
class OrderItem extends Equatable {
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

  @override
  List<Object?> get props => [productId, productName, quantity, price];

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

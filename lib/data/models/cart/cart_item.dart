import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product/product.dart';

/// Cart item model.
/// Immutable data class following Equatable convention.
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];

  double get total => product.price * quantity;

  String get formattedTotal => '₱${total.toStringAsFixed(2)}';

  /// Creates a copy with updated quantity
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Returns a new CartItem with quantity incremented by 1
  CartItem increment() => copyWith(quantity: quantity + 1);

  /// Returns a new CartItem with quantity decremented by 1 (minimum 1)
  CartItem decrement() => copyWith(quantity: quantity > 1 ? quantity - 1 : 1);

  /// Converts CartItem to JSON for Firestore storage.
  /// Stores product snapshot data to handle offline/deleted products.
  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity,
      // Product snapshot for offline/deleted product handling
      'productName': product.name,
      'productPrice': product.price,
      'farmerId': product.farmerId,
      'farmerName': product.farmerName,
      'imageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      'category': product.category.name,
    };
  }

  /// Creates a CartItem from JSON Firestore data.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      product: Product(
        id: json['productId'] as String? ?? '',
        farmerId: json['farmerId'] as String? ?? '',
        farmerName: json['farmerName'] as String? ?? '',
        name: json['productName'] as String? ?? '',
        sku: '', // Not stored in cart snapshot
        currentStock: 0,
        minStock: 0,
        price: (json['productPrice'] as num?)?.toDouble() ?? 0.0,
        sold: 0,
        revenue: 0,
        imageUrls: json['imageUrl'] != null ? [json['imageUrl'] as String] : [],
        category: ProductCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ProductCategory.other,
        ),
      ),
    );
  }
}

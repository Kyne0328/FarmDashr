import 'package:equatable/equatable.dart';

/// Product data model.
/// Follows Single Responsibility Principle - only handles product data.
class Product extends Equatable {
  final String id;
  final String farmerId;
  final String farmerName; // Added
  final String name;
  final String sku;
  final int currentStock;
  final int minStock;
  final double price;
  final int sold;
  final double revenue;
  final String? description;
  final List<String> imageUrls;
  final ProductCategory category;

  const Product({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.minStock,
    required this.price,
    required this.sold,
    required this.revenue,
    this.description,
    this.imageUrls = const [],
    this.category = ProductCategory.other,
  });

  @override
  List<Object?> get props => [
    id,
    farmerId,
    farmerName,
    name,
    sku,
    currentStock,
    minStock,
    price,
    sold,
    revenue,
    description,
    imageUrls,
    category,
  ];

  /// Whether the product is low on stock
  bool get isLowStock => currentStock < minStock;

  /// Formatted price string
  String get formattedPrice => '₱${price.toStringAsFixed(2)}';

  /// Formatted revenue string
  String get formattedRevenue => '₱${revenue.toStringAsFixed(2)}';

  /// Stock display string
  String get stockDisplay => '$currentStock / $minStock';

  /// Creates a copy with updated fields
  Product copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? name,
    String? sku,
    int? currentStock,
    int? minStock,
    double? price,
    int? sold,
    double? revenue,
    String? description,
    List<String>? imageUrls,
    ProductCategory? category,
  }) {
    return Product(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      price: price ?? this.price,
      sold: sold ?? this.sold,
      revenue: revenue ?? this.revenue,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
    );
  }

  /// Creates a Product from Firestore document data
  factory Product.fromJson(Map<String, dynamic> json, String id) {
    return Product(
      id: id,
      farmerId: json['farmerId']?.toString() ?? '',
      farmerName: json['farmerName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      minStock: (json['minStock'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sold: (json['sold'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString(),
      imageUrls:
          (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ??
          (json['imageUrl'] != null ? [json['imageUrl'].toString()] : []),
      category: ProductCategory.values.firstWhere(
        (e) => e.name == json['category']?.toString(),
        orElse: () => ProductCategory.other,
      ),
    );
  }

  /// Converts Product to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'name': name,
      'sku': sku,
      'currentStock': currentStock,
      'minStock': minStock,
      'price': price,
      'sold': sold,
      'revenue': revenue,
      'description': description,
      'imageUrls': imageUrls,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
      'category': category.name,
    };
  }

  /// Sample data for development/testing
  static List<Product> get sampleProducts => [
    const Product(
      id: '1',
      farmerId: 'farmer_1',
      farmerName: 'Green Valley Farm',
      name: 'Organic Tomatoes',
      sku: 'VEG-001',
      currentStock: 45,
      minStock: 20,
      price: 4.99,
      sold: 23,
      revenue: 114.77,
      category: ProductCategory.vegetables,
    ),
    const Product(
      id: '2',
      farmerId: 'farmer_1',
      farmerName: 'Green Valley Farm',
      name: 'Fresh Strawberries',
      sku: 'FRU-002',
      currentStock: 12,
      minStock: 20,
      price: 6.50,
      sold: 31,
      revenue: 201.50,
      category: ProductCategory.fruits,
    ),
    const Product(
      id: '3',
      farmerId: 'farmer_2',
      farmerName: 'Berry Bliss',
      name: 'Sourdough Bread',
      sku: 'BAK-003',
      currentStock: 8,
      minStock: 15,
      price: 5.99,
      sold: 18,
      revenue: 107.82,
      category: ProductCategory.bakery,
    ),
    const Product(
      id: '4',
      farmerId: 'farmer_2',
      farmerName: 'Berry Bliss',
      name: 'Farm Fresh Eggs',
      sku: 'DAI-004',
      currentStock: 30,
      minStock: 15,
      price: 3.49,
      sold: 14,
      revenue: 48.86,
      category: ProductCategory.dairy,
    ),
  ];
}

/// Product category enumeration
enum ProductCategory {
  vegetables,
  fruits,
  bakery,
  dairy,
  meat,
  other;

  String get displayName {
    switch (this) {
      case ProductCategory.vegetables:
        return 'Vegetables';
      case ProductCategory.fruits:
        return 'Fruits';
      case ProductCategory.bakery:
        return 'Bakery';
      case ProductCategory.dairy:
        return 'Dairy';
      case ProductCategory.meat:
        return 'Meat';
      case ProductCategory.other:
        return 'Other';
    }
  }
}

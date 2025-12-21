import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product.dart';

/// Base class for all product states.
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// State while products are being loaded.
class ProductLoading extends ProductState {
  const ProductLoading();
}

/// State when products are successfully loaded.
class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final String searchQuery;

  const ProductLoaded({
    required this.products,
    this.filteredProducts = const [],
    this.searchQuery = '',
  });

  /// Get the products to display (filtered if searching, all otherwise).
  List<Product> get displayProducts =>
      searchQuery.isEmpty ? products : filteredProducts;

  /// Count of low stock products.
  int get lowStockCount => products.where((p) => p.isLowStock).length;

  /// Total revenue from all products.
  double get totalRevenue => products.fold(0.0, (sum, p) => sum + p.revenue);

  /// Total items sold.
  int get totalSold => products.fold(0, (sum, p) => sum + p.sold);

  @override
  List<Object?> get props => [products, filteredProducts, searchQuery];

  /// Create a copy with updated values.
  ProductLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// State when an error occurs.
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when a product operation (add/update/delete) is successful.
class ProductOperationSuccess extends ProductState {
  final String message;
  final List<Product> products;

  const ProductOperationSuccess({
    required this.message,
    required this.products,
  });

  @override
  List<Object?> get props => [message, products];
}

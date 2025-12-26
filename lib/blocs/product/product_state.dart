import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product.dart';

/// Base class for all product states.
abstract class ProductState extends Equatable {
  final String? farmerId;
  const ProductState({this.farmerId});

  @override
  List<Object?> get props => [farmerId];
}

/// Base class for states that contain a list of products.
abstract class ProductDataState extends ProductState {
  final List<Product> products;
  const ProductDataState({required this.products, super.farmerId});

  /// Count of low stock products.
  int get lowStockCount => products.where((p) => p.isLowStock).length;

  /// Total revenue from all products.
  double get totalRevenue => products.fold(0.0, (sum, p) => sum + p.revenue);

  /// Total items sold.
  int get totalSold => products.fold(0, (sum, p) => sum + p.sold);

  @override
  List<Object?> get props => [products, farmerId];
}

/// Initial state before any action.
class ProductInitial extends ProductState {
  const ProductInitial() : super();
}

/// State while products are being loaded.
class ProductLoading extends ProductState {
  const ProductLoading({super.farmerId});
}

/// State when products are successfully loaded.
class ProductLoaded extends ProductDataState {
  final List<Product> filteredProducts;
  final String searchQuery;

  const ProductLoaded({
    required super.products,
    this.filteredProducts = const [],
    this.searchQuery = '',
    super.farmerId,
  });

  /// Get the products to display (filtered if searching, all otherwise).
  List<Product> get displayProducts =>
      searchQuery.isEmpty ? products : filteredProducts;

  @override
  List<Object?> get props => [products, filteredProducts, searchQuery];

  /// Create a copy with updated values.
  ProductLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    String? farmerId,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      farmerId: farmerId ?? this.farmerId,
    );
  }
}

/// State when an error occurs.
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message, {super.farmerId});

  @override
  List<Object?> get props => [message, farmerId];
}

/// State when a product operation (add/update/delete) is successful.
class ProductOperationSuccess extends ProductDataState {
  final String message;

  const ProductOperationSuccess({
    required this.message,
    required super.products,
    super.farmerId,
  });

  @override
  List<Object?> get props => [message, products, farmerId];
}

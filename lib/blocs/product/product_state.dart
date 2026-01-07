import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product/product.dart';

/// Base class for all product states.
abstract class ProductState extends Equatable {
  final String? farmerId;
  final String? excludeFarmerId;
  const ProductState({this.farmerId, this.excludeFarmerId});

  @override
  List<Object?> get props => [farmerId, excludeFarmerId];
}

/// Base class for states that contain a list of products.
abstract class ProductDataState extends ProductState {
  final List<Product> products;
  const ProductDataState({
    required this.products,
    super.farmerId,
    super.excludeFarmerId,
  });

  /// Count of low stock products.
  int get lowStockCount => products.where((p) => p.isLowStock).length;

  /// Total revenue from all products.
  double get totalRevenue => products.fold(0.0, (sum, p) => sum + p.revenue);

  /// Total items sold.
  int get totalSold => products.fold(0, (sum, p) => sum + p.sold);

  @override
  List<Object?> get props => [products, farmerId, excludeFarmerId];
}

/// Initial state before any action.
class ProductInitial extends ProductState {
  const ProductInitial() : super();
}

/// State while products are being loaded.
class ProductLoading extends ProductState {
  const ProductLoading({super.farmerId, super.excludeFarmerId});
}

/// State while a product is being submitted (validating/uploading).
class ProductSubmitting extends ProductDataState {
  const ProductSubmitting({
    required super.products,
    super.farmerId,
    super.excludeFarmerId,
  });
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
    super.excludeFarmerId,
  });

  /// Get the products to display (filtered if searching or excluded, all otherwise).
  List<Product> get displayProducts {
    var result = searchQuery.isEmpty ? products : filteredProducts;
    if (excludeFarmerId != null) {
      result = result.where((p) => p.farmerId != excludeFarmerId).toList();
    }
    return result;
  }

  @override
  List<Object?> get props => [
    products,
    filteredProducts,
    searchQuery,
    farmerId,
    excludeFarmerId,
  ];

  /// Create a copy with updated values.
  ProductLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    String? farmerId,
    String? excludeFarmerId,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      farmerId: farmerId ?? this.farmerId,
      excludeFarmerId: excludeFarmerId ?? this.excludeFarmerId,
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

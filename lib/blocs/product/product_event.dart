import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product.dart';

/// Base class for all product events.
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all products from repository.
class LoadProducts extends ProductEvent {
  final String? farmerId;

  const LoadProducts({this.farmerId});

  @override
  List<Object?> get props => [farmerId];
}

/// Event representing an update in the product list from a stream.
class ProductsUpdated extends ProductEvent {
  final List<Product> products;
  final String? farmerId;

  const ProductsUpdated(this.products, {this.farmerId});

  @override
  List<Object?> get props => [products, farmerId];
}

/// Event to add a new product.
class AddProduct extends ProductEvent {
  final Product product;

  const AddProduct(this.product);

  @override
  List<Object?> get props => [product];
}

/// Event to update an existing product.
class UpdateProduct extends ProductEvent {
  final Product product;

  const UpdateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

/// Event to delete a product by ID.
class DeleteProduct extends ProductEvent {
  final String productId;

  const DeleteProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Event to search products by query.
class SearchProducts extends ProductEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

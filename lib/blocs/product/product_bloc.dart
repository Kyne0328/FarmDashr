import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/repositories/product_repository.dart';
import 'package:farmdashr/blocs/product/product_event.dart';
import 'package:farmdashr/blocs/product/product_state.dart';

/// BLoC for managing product/inventory state.
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc({ProductRepository? repository})
    : _repository = repository ?? ProductRepository(),
      super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<SearchProducts>(_onSearchProducts);
  }

  /// Handle LoadProducts event.
  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final products = await _repository.getAll();
      emit(ProductLoaded(products: products));
    } catch (e) {
      emit(ProductError('Failed to load products: ${e.toString()}'));
    }
  }

  /// Handle AddProduct event.
  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.create(event.product);
      final products = await _repository.getAll();
      emit(
        ProductOperationSuccess(
          message: 'Product added successfully',
          products: products,
        ),
      );
      emit(ProductLoaded(products: products));
    } catch (e) {
      emit(ProductError('Failed to add product: ${e.toString()}'));
    }
  }

  /// Handle UpdateProduct event.
  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.update(event.product);
      final products = await _repository.getAll();
      emit(
        ProductOperationSuccess(
          message: 'Product updated successfully',
          products: products,
        ),
      );
      emit(ProductLoaded(products: products));
    } catch (e) {
      emit(ProductError('Failed to update product: ${e.toString()}'));
    }
  }

  /// Handle DeleteProduct event.
  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.delete(event.productId);
      final products = await _repository.getAll();
      emit(
        ProductOperationSuccess(
          message: 'Product deleted successfully',
          products: products,
        ),
      );
      emit(ProductLoaded(products: products));
    } catch (e) {
      emit(ProductError('Failed to delete product: ${e.toString()}'));
    }
  }

  /// Handle SearchProducts event.
  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProductLoaded) {
      if (event.query.isEmpty) {
        emit(currentState.copyWith(searchQuery: '', filteredProducts: []));
      } else {
        final filtered = currentState.products
            .where(
              (p) => p.name.toLowerCase().contains(event.query.toLowerCase()),
            )
            .toList();
        emit(
          currentState.copyWith(
            searchQuery: event.query,
            filteredProducts: filtered,
          ),
        );
      }
    }
  }
}

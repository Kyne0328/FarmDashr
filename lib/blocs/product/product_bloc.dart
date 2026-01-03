import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/repositories/product/product_repository.dart';
import 'package:farmdashr/blocs/product/product_event.dart';
import 'package:farmdashr/blocs/product/product_state.dart';
import 'package:farmdashr/data/models/product/product.dart'; // Assuming Product model is here

/// BLoC for managing product/inventory state.
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;
  StreamSubscription<List<Product>>? _productsSubscription;

  ProductBloc({ProductRepository? repository})
    : _repository = repository ?? ProductRepository(),
      super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<ProductsUpdated>(_onProductsUpdated);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<SearchProducts>(_onSearchProducts);
  }

  /// Handle LoadProducts event - starts the stream.
  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading(farmerId: event.farmerId));

    await _productsSubscription?.cancel();

    _productsSubscription =
        (event.farmerId != null
                ? _repository.watchByFarmerId(event.farmerId!)
                : _repository.watchAll())
            .listen((products) {
              add(ProductsUpdated(products, farmerId: event.farmerId));
            });
  }

  /// Handle ProductsUpdated event - emits the new data.
  void _onProductsUpdated(ProductsUpdated event, Emitter<ProductState> emit) {
    final currentState = state;
    if (currentState is ProductLoaded && currentState.searchQuery.isNotEmpty) {
      // Re-apply filter if searching
      final filtered = event.products
          .where(
            (p) => p.name.toLowerCase().contains(
              currentState.searchQuery.toLowerCase(),
            ),
          )
          .toList();
      emit(
        currentState.copyWith(
          products: event.products,
          filteredProducts: filtered,
          farmerId: event.farmerId,
        ),
      );
    } else {
      emit(ProductLoaded(products: event.products, farmerId: event.farmerId));
    }
  }

  /// Handle AddProduct event.
  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.create(event.product);
      // No need to manually refresh; the stream will notify us via ProductsUpdated
      if (state is ProductLoaded) {
        emit(
          ProductOperationSuccess(
            message: 'Product added successfully',
            products: (state as ProductLoaded).products,
            farmerId: state.farmerId,
          ),
        );
      }
    } catch (e) {
      emit(
        ProductError(
          'Failed to add product: ${e.toString()}',
          farmerId: state.farmerId,
        ),
      );
    }
  }

  /// Handle UpdateProduct event.
  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.update(event.product);
      if (state is ProductLoaded) {
        emit(
          ProductOperationSuccess(
            message: 'Product updated successfully',
            products: (state as ProductLoaded).products,
            farmerId: state.farmerId,
          ),
        );
      }
    } catch (e) {
      emit(
        ProductError(
          'Failed to update product: ${e.toString()}',
          farmerId: state.farmerId,
        ),
      );
    }
  }

  /// Handle DeleteProduct event.
  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repository.delete(event.productId);
      if (state is ProductLoaded) {
        emit(
          ProductOperationSuccess(
            message: 'Product deleted successfully',
            products: (state as ProductLoaded).products,
            farmerId: state.farmerId,
          ),
        );
      }
    } catch (e) {
      emit(
        ProductError(
          'Failed to delete product: ${e.toString()}',
          farmerId: state.farmerId,
        ),
      );
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

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}

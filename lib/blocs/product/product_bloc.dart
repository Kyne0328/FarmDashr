import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/repositories/product/product_repository.dart';
import 'package:farmdashr/blocs/product/product_event.dart';
import 'package:farmdashr/blocs/product/product_state.dart';
import 'package:farmdashr/data/models/product/product.dart'; // Assuming Product model is here
import 'package:farmdashr/core/error/failures.dart';
import 'package:farmdashr/core/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

/// BLoC for managing product/inventory state.
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;
  final CloudinaryService _cloudinaryService;
  StreamSubscription<List<Product>>? _productsSubscription;

  ProductBloc({
    required ProductRepository repository,
    required CloudinaryService cloudinaryService,
  }) : _repository = repository,
       _cloudinaryService = cloudinaryService,
       super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<ProductsUpdated>(_onProductsUpdated);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<SearchProducts>(_onSearchProducts);
    on<SubmitProductForm>(_onSubmitProductForm);
  }

  /// Handle LoadProducts event - starts the stream.
  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    // If we're loading all products (farmerId is null), and current state has a farmerId,
    // or if we're changing farmers, emit loading and restart subscription.
    if (state.farmerId != event.farmerId) {
      emit(
        ProductLoading(
          farmerId: event.farmerId,
          excludeFarmerId: event.excludeFarmerId,
        ),
      );
    }

    await _productsSubscription?.cancel();

    _productsSubscription =
        (event.farmerId != null
                ? _repository.watchByFarmerId(event.farmerId!)
                : _repository.watchAll())
            .listen((products) {
              add(
                ProductsUpdated(
                  products,
                  farmerId: event.farmerId,
                  excludeFarmerId: event.excludeFarmerId,
                ),
              );
            });
  }

  /// Handle ProductsUpdated event - emits the new data.
  void _onProductsUpdated(ProductsUpdated event, Emitter<ProductState> emit) {
    final currentState = state;

    // Filter out the excluded farmer
    var displayProducts = event.products;
    if (event.excludeFarmerId != null) {
      displayProducts = displayProducts
          .where((p) => p.farmerId != event.excludeFarmerId)
          .toList();
    }

    if (currentState is ProductLoaded && currentState.searchQuery.isNotEmpty) {
      // Re-apply filter if searching
      final filtered = displayProducts
          .where(
            (p) => p.name.toLowerCase().contains(
              currentState.searchQuery.toLowerCase(),
            ),
          )
          .toList();
      emit(
        currentState.copyWith(
          products: displayProducts,
          filteredProducts: filtered,
          farmerId: event.farmerId,
          excludeFarmerId: event.excludeFarmerId,
        ),
      );
    } else {
      emit(
        ProductLoaded(
          products: displayProducts,
          farmerId: event.farmerId,
          excludeFarmerId: event.excludeFarmerId,
        ),
      );
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
      final message = e is Failure
          ? e.message
          : 'Failed to add product: ${e.toString()}';
      emit(ProductError(message, farmerId: state.farmerId));
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
      final message = e is Failure
          ? e.message
          : 'Failed to update product: ${e.toString()}';
      emit(ProductError(message, farmerId: state.farmerId));
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
      final message = e is Failure
          ? e.message
          : 'Failed to delete product: ${e.toString()}';
      emit(ProductError(message, farmerId: state.farmerId));
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

  Future<void> _onSubmitProductForm(
    SubmitProductForm event,
    Emitter<ProductState> emit,
  ) async {
    // Preserve current products while submitting
    final currentProducts = state is ProductDataState
        ? (state as ProductDataState).products
        : <Product>[];

    emit(
      ProductSubmitting(
        products: currentProducts,
        farmerId: state.farmerId,
        excludeFarmerId: state.excludeFarmerId,
      ),
    );

    try {
      // 1. Initial Validation (Server-side compatible checks)
      // Check SKU uniqueness
      final isUnique = await _repository.isSkuUnique(
        event.product.sku,
        event.product.farmerId,
        excludeProductId: event.isUpdate ? event.product.id : null,
      );

      if (!isUnique) {
        emit(
          ProductError(
            'SKU ${event.product.sku} is already taken',
            farmerId: state.farmerId,
          ),
        );
        // Re-emit loaded state so UI can recover?
        // Ideally we'd have a FormSubmissionFailure state that preserves form data,
        // but for now Error state is what we have.
        return;
      }

      // 2. Image Upload
      List<String> finalImageUrls = List.from(event.keptImageUrls);

      if (event.newImages.isNotEmpty) {
        // Filter out non-XFile objects if any, though type safety should prevent this
        final imagesToUpload = event.newImages.whereType<XFile>().toList();
        if (imagesToUpload.isNotEmpty) {
          final uploadedUrls = await _cloudinaryService.uploadImages(
            imagesToUpload,
          );
          finalImageUrls.addAll(uploadedUrls);
        }
      }

      final productToSave = event.product.copyWith(imageUrls: finalImageUrls);

      // 3. Save
      if (event.isUpdate) {
        await _repository.update(productToSave);
        if (state is ProductLoaded) {
          emit(
            ProductOperationSuccess(
              message: 'Product updated successfully',
              products: (state as ProductLoaded).products,
              farmerId: state.farmerId,
            ),
          );
        } else {
          emit(
            ProductOperationSuccess(
              message: 'Product updated successfully',
              products: currentProducts,
              farmerId: state.farmerId,
            ),
          );
        }
      } else {
        await _repository.create(productToSave);
        if (state is ProductLoaded) {
          emit(
            ProductOperationSuccess(
              message: 'Product added successfully',
              products: (state as ProductLoaded).products,
              farmerId: state.farmerId,
            ),
          );
        } else {
          emit(
            ProductOperationSuccess(
              message: 'Product added successfully',
              products: currentProducts,
              farmerId: state.farmerId,
            ),
          );
        }
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to submit product: ${e.toString()}';
      emit(ProductError(message, farmerId: state.farmerId));
    }
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}

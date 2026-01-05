import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/blocs/cart/cart_event.dart';
import 'package:farmdashr/blocs/cart/cart_state.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'package:farmdashr/data/repositories/repositories.dart';

/// BLoC for managing shopping cart state with Firestore persistence.
class CartBloc extends Bloc<CartEvent, CartState> {
  final OrderRepository _orderRepository;
  final CartRepository _cartRepository;
  final ProductRepository _productRepository;
  final UserRepository _userRepository;

  // In-memory cart items (synced with Firestore)
  final List<CartItem> _cartItems = [];

  // Current user ID for persistence
  String? _currentUserId;

  CartBloc({
    required OrderRepository orderRepository,
    required CartRepository cartRepository,
    required ProductRepository productRepository,
    required UserRepository userRepository,
  }) : _orderRepository = orderRepository,
       _cartRepository = cartRepository,
       _productRepository = productRepository,
       _userRepository = userRepository,
       super(const CartInitial()) {
    // Register event handlers
    on<LoadCart>(_onLoadCart);
    on<RefreshCart>(_onRefreshCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<IncrementCartItem>(_onIncrementItem);
    on<DecrementCartItem>(_onDecrementItem);
    on<ClearCart>(_onClearCart);
    on<CheckoutCart>(_onCheckout);
  }

  /// Save cart to Firestore (fire and forget for performance).
  Future<void> _saveCart(List<CartItem> items) async {
    if (_currentUserId != null) {
      try {
        await _cartRepository.saveCart(_currentUserId!, items);
      } catch (_) {
        // Silently fail - cart is still in memory
      }
    }
  }

  /// Handle LoadCart event - loads cart from Firestore.
  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(const CartLoading());
    try {
      _currentUserId = event.userId;

      if (_currentUserId != null) {
        // Load from Firestore
        final items = await _cartRepository.getCart(_currentUserId!);
        _cartItems.clear();
        _cartItems.addAll(items);
      }

      emit(CartLoaded(items: List.from(_cartItems)));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to load cart: ${e.toString()}';
      emit(CartError(message));
    }
  }

  /// Handle RefreshCart event - refreshes product data in cart from Firestore.
  Future<void> _onRefreshCart(
    RefreshCart event,
    Emitter<CartState> emit,
  ) async {
    if (_cartItems.isEmpty) {
      emit(CartLoaded(items: List.from(_cartItems)));
      return;
    }

    try {
      final List<CartItem> refreshedItems = [];
      final List<String> removedProducts = [];

      for (final item in _cartItems) {
        final product = await _productRepository.getById(item.product.id);
        if (product == null) {
          // Product was deleted - track for notification
          removedProducts.add(item.product.name);
          continue;
        }
        // Update cart item with fresh product data
        refreshedItems.add(
          CartItem(
            product: product,
            quantity: item.quantity > product.currentStock
                ? product.currentStock
                : item.quantity,
          ),
        );
      }

      // Update source of truth
      _cartItems.clear();
      _cartItems.addAll(refreshedItems.where((item) => item.quantity > 0));

      // Persist to Firestore
      await _saveCart(_cartItems);

      // Notify about removed or adjusted items
      if (removedProducts.isNotEmpty) {
        emit(
          CartOperationSuccess(
            message: 'Some items were removed as they are no longer available',
            items: List.from(_cartItems),
          ),
        );
      }

      emit(CartLoaded(items: List.from(_cartItems)));
    } catch (e) {
      debugPrint('Error refreshing cart: $e');
      // Silently fail - just emit current items
      emit(CartLoaded(items: List.from(_cartItems)));
    }
  }

  /// Handle AddToCart event - adds a product to the cart.
  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      // Stock Validation with fresh data
      final freshProduct = await _productRepository.getById(event.product.id);
      if (freshProduct == null) {
        emit(const CartError('Product no longer available'));
        return;
      }

      // Create a copy to modify
      final List<CartItem> updatedItems = List.from(_cartItems);

      // Check if product already exists in cart
      final existingIndex = updatedItems.indexWhere(
        (item) => item.product.id == event.product.id,
      );

      if (existingIndex >= 0) {
        final newQuantity =
            updatedItems[existingIndex].quantity + event.quantity;
        if (newQuantity > freshProduct.currentStock) {
          emit(
            CartError(
              'Cannot add more. Only ${freshProduct.currentStock} items left in stock',
            ),
          );
          emit(
            CartLoaded(items: List.from(_cartItems)),
          ); // Re-emit loaded to clear loading state if any
          return;
        }

        // Increment quantity of existing item (immutable update)
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          product: freshProduct, // Update with fresh data too
          quantity: newQuantity,
        );
      } else {
        if (event.quantity > freshProduct.currentStock) {
          emit(
            CartError(
              'Cannot add more. Only ${freshProduct.currentStock} items left in stock',
            ),
          );
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }
        // Add new item to cart
        updatedItems.add(
          CartItem(product: freshProduct, quantity: event.quantity),
        );
      }

      // Update source of truth
      _cartItems.clear();
      _cartItems.addAll(updatedItems);

      // Persist to Firestore using the snapshot
      await _saveCart(updatedItems);

      emit(
        CartOperationSuccess(
          message: '${freshProduct.name} added to cart',
          items: List.from(updatedItems),
        ),
      );
      emit(CartLoaded(items: List.from(updatedItems)));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to add to cart: ${e.toString()}';
      emit(CartError(message));
    }
  }

  /// Handle RemoveFromCart event - removes a product from the cart.
  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final removedItem = _cartItems.firstWhere(
        (item) => item.product.id == event.productId,
        orElse: () => throw Exception('Item not found'),
      );

      // Create a copy to modify
      final List<CartItem> updatedItems = List.from(_cartItems);
      updatedItems.removeWhere((item) => item.product.id == event.productId);

      // Update source of truth
      _cartItems.clear();
      _cartItems.addAll(updatedItems);

      // Persist to Firestore
      await _saveCart(updatedItems);

      emit(
        CartOperationSuccess(
          message: '${removedItem.product.name} removed from cart',
          items: List.from(updatedItems),
        ),
      );
      emit(CartLoaded(items: List.from(updatedItems)));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to remove from cart: ${e.toString()}';
      emit(CartError(message));
    }
  }

  /// Handle UpdateCartItemQuantity event - updates item quantity.
  Future<void> _onUpdateQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) async {
    try {
      if (event.quantity <= 0) {
        // Remove item if quantity is 0 or less
        add(RemoveFromCart(event.productId));
        return;
      }

      final index = _cartItems.indexWhere(
        (item) => item.product.id == event.productId,
      );

      if (index >= 0) {
        // Check fresh stock
        final freshProduct = await _productRepository.getById(event.productId);
        if (freshProduct == null) {
          add(RemoveFromCart(event.productId));
          emit(const CartError('Product no longer available'));
          return;
        }

        if (event.quantity > freshProduct.currentStock) {
          emit(
            CartError(
              'Cannot add more. Only ${freshProduct.currentStock} items left in stock',
            ),
          );
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }

        // Create copy
        final List<CartItem> updatedItems = List.from(_cartItems);
        updatedItems[index] = updatedItems[index].copyWith(
          product: freshProduct,
          quantity: event.quantity,
        );

        // Update source of truth
        _cartItems.clear();
        _cartItems.addAll(updatedItems);

        // Persist to Firestore
        await _saveCart(updatedItems);

        emit(CartLoaded(items: List.from(updatedItems)));
      } else {
        emit(const CartError('Item not found in cart'));
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to update quantity: ${e.toString()}';
      emit(CartError(message));
    }
  }

  /// Handle IncrementCartItem event - increases quantity by 1.
  Future<void> _onIncrementItem(
    IncrementCartItem event,
    Emitter<CartState> emit,
  ) async {
    try {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == event.productId,
      );

      if (index >= 0) {
        // Check fresh stock
        final freshProduct = await _productRepository.getById(event.productId);
        if (freshProduct == null) {
          add(RemoveFromCart(event.productId));
          emit(const CartError('Product no longer available'));
          return;
        }

        final newQuantity = _cartItems[index].quantity + 1;

        if (newQuantity > freshProduct.currentStock) {
          emit(
            CartError(
              'Cannot add more. Only ${freshProduct.currentStock} items left in stock',
            ),
          );
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }

        // Create copy
        final List<CartItem> updatedItems = List.from(_cartItems);
        updatedItems[index] = updatedItems[index].copyWith(
          product: freshProduct,
          quantity: newQuantity,
        );

        // Update source of truth
        _cartItems.clear();
        _cartItems.addAll(updatedItems);

        // Persist to Firestore
        await _saveCart(updatedItems);

        emit(CartLoaded(items: List.from(updatedItems)));
      } else {
        emit(const CartError('Item not found in cart'));
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to increment item: ${e.toString()}';
      emit(CartError(message));
    }
  }

  /// Handle DecrementCartItem event - decreases quantity by 1.
  Future<void> _onDecrementItem(
    DecrementCartItem event,
    Emitter<CartState> emit,
  ) async {
    try {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == event.productId,
      );

      if (index >= 0) {
        if (_cartItems[index].quantity <= 1) {
          // Remove item if quantity would become 0
          add(RemoveFromCart(event.productId));
        } else {
          // Create copy
          final List<CartItem> updatedItems = List.from(_cartItems);
          updatedItems[index] = updatedItems[index].decrement();

          // Update source of truth
          _cartItems.clear();
          _cartItems.addAll(updatedItems);

          // Persist to Firestore
          await _saveCart(updatedItems);

          emit(CartLoaded(items: List.from(updatedItems)));
        }
      } else {
        emit(const CartError('Item not found in cart'));
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to decrement item: ${e.toString()}';
      emit(CartError(message));
    }
  }

  /// Handle ClearCart event - removes all items from the cart.
  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      final hadItems = _cartItems.isNotEmpty;
      _cartItems.clear();

      // Only attempt to clear from Firestore if we have a valid user ID
      // This prevents race conditions during logout
      if (_currentUserId != null && event.clearFromFirestore) {
        try {
          await _cartRepository.clearCart(_currentUserId!);
        } catch (e) {
          // Log but don't fail - local cart is already cleared
          debugPrint('Failed to clear cart from Firestore: $e');
        }
      }

      // Only show success message if cart actually had items
      if (hadItems && event.showNotification) {
        emit(const CartOperationSuccess(message: 'Cart cleared', items: []));
      }
      emit(const CartLoaded(items: []));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to clear cart: ${e.toString()}';
      emit(CartError(message));
    }
  }

  /// Handle CheckoutCart event - processes the checkout.
  Future<void> _onCheckout(CheckoutCart event, Emitter<CartState> emit) async {
    try {
      if (_cartItems.isEmpty) {
        emit(const CartError('Cart is empty'));
        return;
      }

      emit(const CartLoading());

      // Pre-checkout Stock & Price Validation
      // Fetch fresh product data to ensure current prices and stock
      final Map<String, Product> refreshedProducts = {};

      for (final item in _cartItems) {
        final product = await _productRepository.getById(item.product.id);
        if (product == null) {
          emit(CartError('Product ${item.product.name} no longer exists.'));
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }
        if (product.currentStock < item.quantity) {
          emit(
            CartError(
              'Insufficient stock for ${product.name}. Available: ${product.currentStock}',
            ),
          );
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }
        // Store refreshed product for use in order creation
        refreshedProducts[product.id] = product;
      }

      // Group items by farmerId
      final Map<String, List<CartItem>> itemsByFarmer = {};
      for (final item in _cartItems) {
        if (!itemsByFarmer.containsKey(item.product.farmerId)) {
          itemsByFarmer[item.product.farmerId] = [];
        }
        itemsByFarmer[item.product.farmerId]!.add(item);
      }

      final List<String> createdOrderIds = [];

      // Create an order for each farmer group
      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final farmerItems = entry.value;

        // Fetch farmer's current profile to get up-to-date name
        String farmerName;
        try {
          final farmerProfile = await _userRepository.getById(farmerId);
          // Prefer businessInfo.farmName, fall back to profile name, then product name
          farmerName =
              farmerProfile?.businessInfo?.farmName ??
              farmerProfile?.name ??
              refreshedProducts[farmerItems.first.product.id]?.farmerName ??
              farmerItems.first.product.farmerName;
        } catch (e) {
          // Fall back to product's farmer name if profile fetch fails
          farmerName =
              refreshedProducts[farmerItems.first.product.id]?.farmerName ??
              farmerItems.first.product.farmerName;
        }

        double subtotal = 0;
        final List<OrderItem> orderItems = [];

        for (final item in farmerItems) {
          // Use refreshed product data for current price
          final currentProduct = refreshedProducts[item.product.id]!;
          final itemTotal = currentProduct.price * item.quantity;
          subtotal += itemTotal;
          orderItems.add(
            OrderItem(
              productId: currentProduct.id,
              productName: currentProduct.name,
              productImageUrl: currentProduct.imageUrls.isNotEmpty
                  ? currentProduct.imageUrls.first
                  : null,
              quantity: item.quantity,
              price: currentProduct.price, // Current price from Firestore
            ),
          );
        }

        // Total is just the subtotal now
        final double totalAmount = subtotal;

        final details = event.pickupDetails[farmerId];
        if (details == null) {
          throw Exception('Missing pickup details for farmer $farmerName');
        }

        final order = Order(
          id: '', // Firestore will generate this
          customerId: event.customerId,
          customerName: event.customerName,
          farmerId: farmerId,
          farmerName: farmerName,
          itemCount: farmerItems.fold(0, (sum, item) => sum + item.quantity),
          createdAt: DateTime.now(),
          status: OrderStatus.pending,
          amount: totalAmount,
          items: orderItems,
          pickupLocation: details.pickupLocation,
          pickupDate: details.pickupDate,
          pickupTime: details.pickupTime,
          specialInstructions: details.specialInstructions,
        );

        final createdOrder = await _orderRepository.create(order);
        createdOrderIds.add(createdOrder.id);
      }

      // Clear the cart after successful checkout
      _cartItems.clear();

      // Clear from Firestore
      if (_currentUserId != null) {
        await _cartRepository.clearCart(_currentUserId!);
      }

      emit(
        CartCheckoutSuccess(
          orderId: createdOrderIds.isNotEmpty ? createdOrderIds.first : '',
          message: 'Orders placed successfully!',
        ),
      );
      emit(const CartLoaded(items: []));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to checkout: ${e.toString()}';
      emit(CartError(message));
      // Reload cart to ensure UI is in sync
      emit(CartLoaded(items: List.from(_cartItems)));
    }
  }
}

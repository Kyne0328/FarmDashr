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

  // In-memory cart items (synced with Firestore)
  final List<CartItem> _cartItems = [];

  // Current user ID for persistence
  String? _currentUserId;

  CartBloc({
    required OrderRepository orderRepository,
    required CartRepository cartRepository,
  }) : _orderRepository = orderRepository,
       _cartRepository = cartRepository,
       super(const CartInitial()) {
    // Register event handlers
    on<LoadCart>(_onLoadCart);
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

  /// Handle AddToCart event - adds a product to the cart.
  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      // Create a copy to modify
      final List<CartItem> updatedItems = List.from(_cartItems);

      // Check if product already exists in cart
      final existingIndex = updatedItems.indexWhere(
        (item) => item.product.id == event.product.id,
      );

      if (existingIndex >= 0) {
        final newQuantity =
            updatedItems[existingIndex].quantity + event.quantity;
        if (newQuantity > event.product.currentStock) {
          emit(
            CartError(
              'Cannot add more. only ${event.product.currentStock} items left in stock',
            ),
          );
          emit(
            CartLoaded(items: List.from(_cartItems)),
          ); // Re-emit loaded to clear loading state if any
          return;
        }

        // Increment quantity of existing item (immutable update)
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          quantity: newQuantity,
        );
      } else {
        if (event.quantity > event.product.currentStock) {
          emit(
            CartError(
              'Cannot add more. only ${event.product.currentStock} items left in stock',
            ),
          );
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }
        // Add new item to cart
        updatedItems.add(
          CartItem(product: event.product, quantity: event.quantity),
        );
      }

      // Update source of truth
      _cartItems.clear();
      _cartItems.addAll(updatedItems);

      // Persist to Firestore using the snapshot
      await _saveCart(updatedItems);

      emit(
        CartOperationSuccess(
          message: '${event.product.name} added to cart',
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
        final currentStock = _cartItems[index].product.currentStock;
        if (event.quantity > currentStock) {
          emit(
            CartError(
              'Cannot add more. only $currentStock items left in stock',
            ),
          );
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }

        // Create copy
        final List<CartItem> updatedItems = List.from(_cartItems);
        updatedItems[index] = updatedItems[index].copyWith(
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
        final currentStock = _cartItems[index].product.currentStock;
        final newQuantity = _cartItems[index].quantity + 1;

        if (newQuantity > currentStock) {
          emit(
            CartError(
              'Cannot add more. only $currentStock items left in stock',
            ),
          );
          emit(CartLoaded(items: List.from(_cartItems)));
          return;
        }

        // Create copy
        final List<CartItem> updatedItems = List.from(_cartItems);
        updatedItems[index] = updatedItems[index].increment();

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
      _cartItems.clear();

      // Clear from Firestore
      if (_currentUserId != null) {
        await _cartRepository.clearCart(_currentUserId!);
      }

      emit(const CartOperationSuccess(message: 'Cart cleared', items: []));
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
      final productRepo = FirestoreProductRepository();
      final Map<String, Product> refreshedProducts = {};

      for (final item in _cartItems) {
        final product = await productRepo.getById(item.product.id);
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

      final List<Future<Order>> orderFutures = [];

      // Fetch farmer profiles for up-to-date names
      final userRepo = FirestoreUserRepository();

      // Create an order for each farmer group
      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final farmerItems = entry.value;

        // Fetch farmer's current profile to get up-to-date name
        String farmerName;
        try {
          final farmerProfile = await userRepo.getById(farmerId);
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

        orderFutures.add(_orderRepository.create(order));
      }

      // Wait for all orders to be created
      await Future.wait(orderFutures);

      // Clear the cart after successful checkout
      _cartItems.clear();

      // Clear from Firestore
      if (_currentUserId != null) {
        await _cartRepository.clearCart(_currentUserId!);
      }

      emit(
        const CartCheckoutSuccess(
          orderId: '', // No single order ID anymore
          message: 'Orders placed successfully!',
        ),
      );
      emit(const CartLoaded(items: []));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to checkout: ${e.toString()}';
      emit(CartError(message));
    }
  }
}

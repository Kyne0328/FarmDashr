import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/models/cart_item.dart';
import 'package:farmdashr/blocs/cart/cart_event.dart';
import 'package:farmdashr/blocs/cart/cart_state.dart';

/// BLoC for managing shopping cart state.
class CartBloc extends Bloc<CartEvent, CartState> {
  // In-memory cart items (could be backed by local storage or Firebase later)
  final List<CartItem> _cartItems = [];

  CartBloc() : super(const CartInitial()) {
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

  /// Handle LoadCart event - initializes the cart.
  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(const CartLoading());
    try {
      // For now, just emit the current in-memory cart
      // Later, this could load from SharedPreferences or Firebase
      emit(CartLoaded(items: List.from(_cartItems)));
    } catch (e) {
      emit(CartError('Failed to load cart: ${e.toString()}'));
    }
  }

  /// Handle AddToCart event - adds a product to the cart.
  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      // Check if product already exists in cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == event.product.id,
      );

      if (existingIndex >= 0) {
        // Increment quantity of existing item (immutable update)
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + event.quantity,
        );
      } else {
        // Add new item to cart
        _cartItems.add(
          CartItem(product: event.product, quantity: event.quantity),
        );
      }

      emit(
        CartOperationSuccess(
          message: '${event.product.name} added to cart',
          items: List.from(_cartItems),
        ),
      );
      emit(CartLoaded(items: List.from(_cartItems)));
    } catch (e) {
      emit(CartError('Failed to add to cart: ${e.toString()}'));
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

      _cartItems.removeWhere((item) => item.product.id == event.productId);

      emit(
        CartOperationSuccess(
          message: '${removedItem.product.name} removed from cart',
          items: List.from(_cartItems),
        ),
      );
      emit(CartLoaded(items: List.from(_cartItems)));
    } catch (e) {
      emit(CartError('Failed to remove from cart: ${e.toString()}'));
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
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: event.quantity,
        );
        emit(CartLoaded(items: List.from(_cartItems)));
      } else {
        emit(const CartError('Item not found in cart'));
      }
    } catch (e) {
      emit(CartError('Failed to update quantity: ${e.toString()}'));
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
        _cartItems[index] = _cartItems[index].increment();
        emit(CartLoaded(items: List.from(_cartItems)));
      } else {
        emit(const CartError('Item not found in cart'));
      }
    } catch (e) {
      emit(CartError('Failed to increment item: ${e.toString()}'));
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
          _cartItems[index] = _cartItems[index].decrement();
          emit(CartLoaded(items: List.from(_cartItems)));
        }
      } else {
        emit(const CartError('Item not found in cart'));
      }
    } catch (e) {
      emit(CartError('Failed to decrement item: ${e.toString()}'));
    }
  }

  /// Handle ClearCart event - removes all items from the cart.
  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      _cartItems.clear();
      emit(const CartOperationSuccess(message: 'Cart cleared', items: []));
      emit(const CartLoaded(items: []));
    } catch (e) {
      emit(CartError('Failed to clear cart: ${e.toString()}'));
    }
  }

  /// Handle CheckoutCart event - processes the checkout.
  Future<void> _onCheckout(CheckoutCart event, Emitter<CartState> emit) async {
    try {
      if (_cartItems.isEmpty) {
        emit(const CartError('Cart is empty'));
        return;
      }

      // TODO: Create order in OrderBloc/OrderRepository
      // For now, just generate a mock order ID
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // Clear the cart after successful checkout
      _cartItems.clear();

      emit(
        CartCheckoutSuccess(
          orderId: orderId,
          message: 'Order placed successfully!',
        ),
      );
      emit(const CartLoaded(items: []));
    } catch (e) {
      emit(CartError('Failed to checkout: ${e.toString()}'));
    }
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/repositories/order/order_repository.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/blocs/order/order_event.dart';
import 'package:farmdashr/presentation/extensions/enum_extensions.dart';
import 'package:farmdashr/blocs/order/order_state.dart';
import 'package:farmdashr/core/error/failures.dart';

/// BLoC for managing order state.
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;
  OrderRepository get repository => _repository;

  StreamSubscription? _ordersSubscription;

  OrderBloc({required OrderRepository repository})
    : _repository = repository,
      super(const OrderInitial()) {
    // Register event handlers
    on<LoadOrders>(_onLoadOrders);
    on<LoadFarmerOrders>(_onLoadFarmerOrders);
    on<LoadCustomerOrders>(_onLoadCustomerOrders);
    on<WatchCustomerOrders>(_onWatchCustomerOrders);
    on<WatchFarmerOrders>(_onWatchFarmerOrders);
    on<OrdersReceived>(_onOrdersReceived);
    on<LoadOrdersByStatus>(_onLoadOrdersByStatus);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrder>(_onUpdateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<DeleteOrder>(_onDeleteOrder);
    on<SearchOrders>(_onSearchOrders);
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }

  /// Handle LoadOrders event - fetches all orders from repository.
  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    // Only show loading if we aren't already loaded with data
    if (state is! OrderLoaded) {
      emit(const OrderLoading());
    }

    try {
      final orders = await _repository.getAll();
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to load orders: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle LoadFarmerOrders event - fetches orders for a specific farmer.
  Future<void> _onLoadFarmerOrders(
    LoadFarmerOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await _repository.getByFarmerId(event.farmerId);
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to load farmer orders: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle LoadCustomerOrders event - fetches orders for a specific customer.
  Future<void> _onLoadCustomerOrders(
    LoadCustomerOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await _repository.getByCustomerId(event.customerId);
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to load customer orders: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle WatchCustomerOrders event - subscribes to real-time customer order updates.
  Future<void> _onWatchCustomerOrders(
    WatchCustomerOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    await _ordersSubscription?.cancel();
    _ordersSubscription = _repository
        .watchByCustomerId(event.customerId)
        .listen((orders) => add(OrdersReceived(orders)));
  }

  /// Handle WatchFarmerOrders event - subscribes to real-time farmer order updates.
  Future<void> _onWatchFarmerOrders(
    WatchFarmerOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    await _ordersSubscription?.cancel();
    _ordersSubscription = _repository
        .watchByFarmerId(event.farmerId)
        .listen((orders) => add(OrdersReceived(orders)));
  }

  /// Handle OrdersReceived event - updates state when orders are received from stream.
  void _onOrdersReceived(OrdersReceived event, Emitter<OrderState> emit) {
    emit(OrderLoaded(orders: event.orders));
  }

  /// Handle LoadOrdersByStatus event - fetches orders filtered by status.
  Future<void> _onLoadOrdersByStatus(
    LoadOrdersByStatus event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await _repository.getByStatus(event.status);
      emit(OrderLoaded(orders: orders, statusFilter: event.status));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to load orders: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle CreateOrder event - creates a new order.
  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final newOrder = await _repository.create(event.order);
      final currentState = state;

      if (currentState is OrderLoaded) {
        final updatedOrders = [newOrder, ...currentState.orders];
        emit(
          OrderOperationSuccess(
            message: 'Order created successfully',
            orders: updatedOrders,
          ),
        );
        emit(currentState.copyWith(orders: updatedOrders));
      } else {
        emit(
          const OrderOperationSuccess(
            message: 'Order created successfully',
            orders: [],
          ),
        );
        // Note: Real-time streams will handle emitting the new OrderLoaded state
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to create order: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle UpdateOrder event - updates an existing order.
  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _repository.update(event.order);
      final currentState = state;

      if (currentState is OrderLoaded) {
        final updatedOrders = currentState.orders
            .map((o) => o.id == event.order.id ? event.order : o)
            .toList();
        emit(
          OrderOperationSuccess(
            message: 'Order updated successfully',
            orders: updatedOrders,
          ),
        );
        emit(currentState.copyWith(orders: updatedOrders));
      } else {
        emit(
          const OrderOperationSuccess(
            message: 'Order updated successfully',
            orders: [],
          ),
        );
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to update order: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle UpdateOrderStatus event - updates only the status of an order.
  /// Cancelled orders cannot be modified back to any other status.
  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderState> emit,
  ) async {
    try {
      // Prevent cancelled orders from being modified
      final currentState = state;
      if (currentState is OrderLoaded) {
        final existingOrder = currentState.orders.firstWhere(
          (o) => o.id == event.orderId,
          orElse: () => throw Exception('Order not found'),
        );

        if (existingOrder.status == OrderStatus.cancelled) {
          emit(const OrderError('Cancelled orders cannot be modified'));
          return;
        }
      }

      await _repository.updateStatus(event.orderId, event.newStatus);

      if (currentState is OrderLoaded) {
        final updatedOrders = currentState.orders.map((o) {
          if (o.id == event.orderId) {
            return o.copyWith(status: event.newStatus);
          }
          return o;
        }).toList();

        emit(
          OrderOperationSuccess(
            message: 'Order status updated to ${event.newStatus.displayName}',
            orders: updatedOrders,
          ),
        );
        emit(currentState.copyWith(orders: updatedOrders));
      } else {
        emit(
          OrderOperationSuccess(
            message: 'Order status updated to ${event.newStatus.displayName}',
            orders: const [],
          ),
        );
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to update order status: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle DeleteOrder event - marks an order as cancelled instead of deleting.
  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _repository.updateStatus(event.orderId, OrderStatus.cancelled);
      final currentState = state;

      if (currentState is OrderLoaded) {
        final updatedOrders = currentState.orders.map((o) {
          if (o.id == event.orderId) {
            return o.copyWith(status: OrderStatus.cancelled);
          }
          return o;
        }).toList();

        emit(
          OrderOperationSuccess(
            message: 'Order cancelled successfully',
            orders: updatedOrders,
          ),
        );
        emit(currentState.copyWith(orders: updatedOrders));
      } else {
        emit(
          const OrderOperationSuccess(
            message: 'Order cancelled successfully',
            orders: [],
          ),
        );
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to cancel order: ${e.toString()}';
      emit(OrderError(message));
    }
  }

  /// Handle SearchOrders event - filters orders by customer name or order ID.
  Future<void> _onSearchOrders(
    SearchOrders event,
    Emitter<OrderState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrderLoaded) {
      if (event.query.isEmpty) {
        // Clear search - show all orders
        emit(currentState.copyWith(searchQuery: '', filteredOrders: []));
      } else {
        // Filter orders by customer name or order ID
        final query = event.query.toLowerCase();
        final filtered = currentState.orders.where((order) {
          return order.customerName.toLowerCase().contains(query) ||
              order.id.toLowerCase().contains(query);
        }).toList();

        emit(
          currentState.copyWith(
            searchQuery: event.query,
            filteredOrders: filtered,
          ),
        );
      }
    }
  }
}

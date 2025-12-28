import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/repositories/order_repository.dart';
import 'package:farmdashr/blocs/order/order_event.dart';
import 'package:farmdashr/blocs/order/order_state.dart';

/// BLoC for managing order state.
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;
  OrderRepository get repository => _repository;

  OrderBloc({OrderRepository? repository})
    : _repository = repository ?? OrderRepository(),
      super(const OrderInitial()) {
    // Register event handlers
    on<LoadOrders>(_onLoadOrders);
    on<LoadOrdersByStatus>(_onLoadOrdersByStatus);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrder>(_onUpdateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<DeleteOrder>(_onDeleteOrder);
    on<SearchOrders>(_onSearchOrders);
  }

  /// Handle LoadOrders event - fetches all orders from repository.
  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final orders = await _repository.getAll();
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
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
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
  }

  /// Handle CreateOrder event - creates a new order.
  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _repository.create(event.order);
      final orders = await _repository.getAll();
      emit(
        OrderOperationSuccess(
          message: 'Order created successfully',
          orders: orders,
        ),
      );
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      emit(OrderError('Failed to create order: ${e.toString()}'));
    }
  }

  /// Handle UpdateOrder event - updates an existing order.
  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _repository.update(event.order);
      final orders = await _repository.getAll();
      emit(
        OrderOperationSuccess(
          message: 'Order updated successfully',
          orders: orders,
        ),
      );
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      emit(OrderError('Failed to update order: ${e.toString()}'));
    }
  }

  /// Handle UpdateOrderStatus event - updates only the status of an order.
  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _repository.updateStatus(event.orderId, event.newStatus);
      final orders = await _repository.getAll();
      emit(
        OrderOperationSuccess(
          message: 'Order status updated to ${event.newStatus.displayName}',
          orders: orders,
        ),
      );
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      emit(OrderError('Failed to update order status: ${e.toString()}'));
    }
  }

  /// Handle DeleteOrder event - deletes an order by ID.
  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _repository.delete(event.orderId);
      final orders = await _repository.getAll();
      emit(
        OrderOperationSuccess(
          message: 'Order deleted successfully',
          orders: orders,
        ),
      );
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      emit(OrderError('Failed to delete order: ${e.toString()}'));
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

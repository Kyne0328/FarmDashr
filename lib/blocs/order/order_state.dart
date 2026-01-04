import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/order/order.dart';

/// Base class for all order states.
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// State while orders are being loaded.
class OrderLoading extends OrderState {
  const OrderLoading();
}

/// State when orders are successfully loaded.
class OrderLoaded extends OrderState {
  final List<Order> orders;
  final List<Order> filteredOrders;
  final String searchQuery;
  final OrderStatus? statusFilter;

  const OrderLoaded({
    required this.orders,
    this.filteredOrders = const [],
    this.searchQuery = '',
    this.statusFilter,
  });

  /// Get the orders to display (filtered if searching, all otherwise).
  List<Order> get displayOrders =>
      searchQuery.isEmpty ? orders : filteredOrders;

  /// Orders that are active (for "Current" tab).
  List<Order> get currentOrders => orders
      .where(
        (o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready,
      )
      .toList();

  /// Orders that are finished (for "History" tab).
  List<Order> get historyOrders => orders
      .where(
        (o) =>
            o.status == OrderStatus.completed ||
            o.status == OrderStatus.cancelled,
      )
      .toList();

  /// Count of pending orders.
  int get pendingCount =>
      orders.where((o) => o.status == OrderStatus.pending).length;

  /// Count of ready orders.
  int get readyCount =>
      orders.where((o) => o.status == OrderStatus.ready).length;

  /// Count of preparing orders.
  int get preparingCount =>
      orders.where((o) => o.status == OrderStatus.preparing).length;

  /// Count of completed orders.
  int get completedCount =>
      orders.where((o) => o.status == OrderStatus.completed).length;

  /// Total revenue from all orders.
  double get totalRevenue => orders.fold(0.0, (sum, o) => sum + o.amount);

  /// Total number of items across all orders.
  int get totalItems => orders.fold(0, (sum, o) => sum + o.itemCount);

  @override
  List<Object?> get props => [
    orders,
    filteredOrders,
    searchQuery,
    statusFilter,
  ];

  /// Create a copy with updated values.
  OrderLoaded copyWith({
    List<Order>? orders,
    List<Order>? filteredOrders,
    String? searchQuery,
    OrderStatus? statusFilter,
  }) {
    return OrderLoaded(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

/// State when an error occurs.
class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when an order operation (create/update/delete) is successful.
class OrderOperationSuccess extends OrderState {
  final String message;
  final List<Order> orders;

  const OrderOperationSuccess({required this.message, required this.orders});

  @override
  List<Object?> get props => [message, orders];
}

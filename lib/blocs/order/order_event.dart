import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/order.dart';

/// Base class for all order events.
/// All events extend Equatable for value comparison.
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all orders from repository.
class LoadOrders extends OrderEvent {
  const LoadOrders();
}

/// Event to load orders filtered by status.
class LoadOrdersByStatus extends OrderEvent {
  final OrderStatus status;

  const LoadOrdersByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// Event to create a new order.
class CreateOrder extends OrderEvent {
  final Order order;

  const CreateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

/// Event to update an existing order.
class UpdateOrder extends OrderEvent {
  final Order order;

  const UpdateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

/// Event to update only the status of an order.
class UpdateOrderStatus extends OrderEvent {
  final String orderId;
  final OrderStatus newStatus;

  const UpdateOrderStatus({required this.orderId, required this.newStatus});

  @override
  List<Object?> get props => [orderId, newStatus];
}

/// Event to delete an order by ID.
class DeleteOrder extends OrderEvent {
  final String orderId;

  const DeleteOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Event to search orders by customer name or order ID.
class SearchOrders extends OrderEvent {
  final String query;

  const SearchOrders(this.query);

  @override
  List<Object?> get props => [query];
}

import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository interface for managing Order data.
abstract class OrderRepository implements BaseRepository<Order, String> {
  /// Get orders by status
  Future<List<Order>> getByStatus(OrderStatus status);

  /// Get orders for a specific farmer
  Future<List<Order>> getByFarmerId(String farmerId);

  /// Get pending orders count
  Future<int> getPendingCount();

  /// Get ready orders count
  Future<int> getReadyCount();

  /// Update order status and notify customer
  Future<Order> updateStatus(String id, OrderStatus newStatus);

  /// Stream of all orders (real-time updates)
  Stream<List<Order>> watchAll();

  /// Stream of orders for a specific farmer
  Stream<List<Order>> watchByFarmerId(String farmerId);

  /// Get orders for a specific customer
  Future<List<Order>> getByCustomerId(String customerId);

  /// Stream of orders for a specific customer
  Stream<List<Order>> watchByCustomerId(String customerId);
}

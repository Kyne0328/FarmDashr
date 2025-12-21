import 'package:farmdashr/data/models/order.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository for managing Order data.
///
/// Currently uses mock data. Replace implementations with actual
/// API calls or database queries when backend is ready.
class OrderRepository implements BaseRepository<Order, String> {
  // In-memory cache for demo purposes
  final List<Order> _orders = List.from(Order.sampleOrders);

  @override
  Future<List<Order>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_orders);
  }

  @override
  Future<Order?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Order> create(Order item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.add(item);
    return item;
  }

  @override
  Future<Order> update(Order item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((o) => o.id == item.id);
    if (index != -1) {
      _orders[index] = item;
    }
    return item;
  }

  @override
  Future<bool> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders.removeAt(index);
      return true;
    }
    return false;
  }

  /// Get orders by status
  Future<List<Order>> getByStatus(OrderStatus status) async {
    final all = await getAll();
    return all.where((o) => o.status == status).toList();
  }

  /// Get pending orders count
  Future<int> getPendingCount() async {
    final pending = await getByStatus(OrderStatus.pending);
    return pending.length;
  }

  /// Get ready orders count
  Future<int> getReadyCount() async {
    final ready = await getByStatus(OrderStatus.ready);
    return ready.length;
  }

  /// Update order status
  Future<Order> updateStatus(String id, OrderStatus newStatus) async {
    final order = await getById(id);
    if (order != null) {
      final updated = order.copyWith(status: newStatus);
      return update(updated);
    }
    throw Exception('Order not found');
  }
}

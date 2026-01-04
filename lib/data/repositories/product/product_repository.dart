import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository interface for managing Product data.
abstract class ProductRepository implements BaseRepository<Product, String> {
  /// Get products that are low on stock for a specific farmer
  Future<List<Product>> getLowStockProducts(String farmerId);

  /// Get products for a specific farmer
  Future<List<Product>> getByFarmerId(String farmerId);

  /// Check if a SKU is unique within a farmer's inventory
  Future<bool> isSkuUnique(
    String sku,
    String farmerId, {
    String? excludeProductId,
  });

  /// Get products by category for a specific farmer
  Future<List<Product>> getByCategory(
    ProductCategory category, {
    String? farmerId,
  });

  /// Search products by name for a specific farmer
  Future<List<Product>> search(String query, {String? farmerId});

  /// Stream of all products (real-time updates)
  Stream<List<Product>> watchAll();

  /// Stream of products for a specific farmer
  Stream<List<Product>> watchByFarmerId(String farmerId);

  /// Decrement stock and update sold/revenue for products in an order
  Future<void> decrementStock(List<OrderItem> items);

  /// Increment stock back for products in a cancelled order
  Future<void> incrementStock(List<OrderItem> items);
}

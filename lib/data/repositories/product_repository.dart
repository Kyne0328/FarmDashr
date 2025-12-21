import 'package:farmdashr/data/models/product.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository for managing Product data.
///
/// Currently uses mock data. Replace implementations with actual
/// API calls or database queries when backend is ready.
class ProductRepository implements BaseRepository<Product, String> {
  // In-memory cache for demo purposes
  final List<Product> _products = List.from(Product.sampleProducts);

  @override
  Future<List<Product>> getAll() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_products);
  }

  @override
  Future<Product?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> create(Product item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _products.add(item);
    return item;
  }

  @override
  Future<Product> update(Product item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _products.indexWhere((p) => p.id == item.id);
    if (index != -1) {
      _products[index] = item;
    }
    return item;
  }

  @override
  Future<bool> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products.removeAt(index);
      return true;
    }
    return false;
  }

  /// Get products that are low on stock
  Future<List<Product>> getLowStockProducts() async {
    final all = await getAll();
    return all.where((p) => p.isLowStock).toList();
  }

  /// Get products by category
  Future<List<Product>> getByCategory(ProductCategory category) async {
    final all = await getAll();
    return all.where((p) => p.category == category).toList();
  }

  /// Search products by name
  Future<List<Product>> search(String query) async {
    final all = await getAll();
    final lowerQuery = query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
  }
}

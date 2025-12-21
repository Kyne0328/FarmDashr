import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/product.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository for managing Product data in Firestore.
class ProductRepository implements BaseRepository<Product, String> {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('products');

  @override
  Future<List<Product>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Product.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<Product> create(Product item) async {
    final docRef = await _collection.add(item.toJson());
    return item.copyWith(id: docRef.id);
  }

  @override
  Future<Product> update(Product item) async {
    await _collection.doc(item.id).update(item.toJson());
    return item;
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get products that are low on stock
  Future<List<Product>> getLowStockProducts() async {
    final all = await getAll();
    return all.where((p) => p.isLowStock).toList();
  }

  /// Get products by category
  Future<List<Product>> getByCategory(ProductCategory category) async {
    final snapshot = await _collection
        .where('category', isEqualTo: category.name)
        .get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Search products by name
  Future<List<Product>> search(String query) async {
    final all = await getAll();
    final lowerQuery = query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Stream of all products (real-time updates)
  Stream<List<Product>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Product.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'product_repository.dart';

/// Firestore implementation of Product repository.
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirestoreProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('products');

  DatabaseFailure _handleFirebaseException(Object e) {
    if (e is FirebaseException) {
      return DatabaseFailure(
        e.message ?? 'A database error occurred',
        code: e.code,
      );
    }
    return DatabaseFailure(e.toString());
  }

  @override
  Future<List<Product>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<Product?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Product.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<Product> create(Product item) async {
    try {
      final docRef = await _collection.add(item.toJson());
      return item.copyWith(id: docRef.id);
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<Product> update(Product item) async {
    try {
      await _collection.doc(item.id).update(item.toJson());
      return item;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<List<Product>> getLowStockProducts(String farmerId) async {
    final products = await getByFarmerId(farmerId);
    return products.where((p) => p.isLowStock).toList();
  }

  @override
  Future<List<Product>> getByFarmerId(String farmerId) async {
    final snapshot = await _collection
        .where('farmerId', isEqualTo: farmerId)
        .get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<bool> isSkuUnique(
    String sku,
    String farmerId, {
    String? excludeProductId,
  }) async {
    final snapshot = await _collection
        .where('farmerId', isEqualTo: farmerId)
        .where('sku', isEqualTo: sku)
        .get();

    if (snapshot.docs.isEmpty) return true;

    if (excludeProductId != null) {
      return snapshot.docs.every((doc) => doc.id == excludeProductId);
    }

    return false;
  }

  @override
  Future<List<Product>> getByCategory(
    ProductCategory category, {
    String? farmerId,
  }) async {
    Query<Map<String, dynamic>> query = _collection.where(
      'category',
      isEqualTo: category.name,
    );
    if (farmerId != null) {
      query = query.where('farmerId', isEqualTo: farmerId);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<Product>> search(String query, {String? farmerId}) async {
    final products = farmerId != null
        ? await getByFarmerId(farmerId)
        : await getAll();
    final lowerQuery = query.toLowerCase();
    return products
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Stream<List<Product>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Product.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }

  @override
  Stream<List<Product>> watchByFarmerId(String farmerId) {
    return _collection
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> decrementStock(List<OrderItem> items) async {
    if (items.isEmpty) return;

    final batch = _firestore.batch();

    for (final item in items) {
      if (item.productId.isEmpty) continue;

      final docRef = _collection.doc(item.productId);

      batch.update(docRef, {
        'currentStock': FieldValue.increment(-item.quantity),
      });
    }

    await batch.commit();
  }

  @override
  Future<void> incrementStock(List<OrderItem> items) async {
    if (items.isEmpty) return;

    final batch = _firestore.batch();

    for (final item in items) {
      if (item.productId.isEmpty) continue;

      final docRef = _collection.doc(item.productId);

      batch.update(docRef, {
        'currentStock': FieldValue.increment(item.quantity),
      });
    }

    await batch.commit();
  }

  @override
  Future<void> updateSalesMetrics(List<OrderItem> items) async {
    if (items.isEmpty) return;

    final batch = _firestore.batch();

    for (final item in items) {
      if (item.productId.isEmpty) continue;

      final docRef = _collection.doc(item.productId);

      batch.update(docRef, {
        'sold': FieldValue.increment(item.quantity),
        'revenue': FieldValue.increment(item.quantity * item.price),
      });
    }

    await batch.commit();
  }
}

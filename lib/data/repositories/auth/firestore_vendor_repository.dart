import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'vendor_repository.dart';

/// Firestore implementation of Vendor (Farmer) repository.
class FirestoreVendorRepository implements VendorRepository {
  final FirebaseFirestore _firestore;

  FirestoreVendorRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

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
  Stream<List<UserProfile>> watchVendors() {
    return _collection
        .where('userType', isEqualTo: UserType.farmer.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserProfile.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<UserProfile?> getVendorById(String vendorId) async {
    try {
      final doc = await _collection.doc(vendorId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }
}

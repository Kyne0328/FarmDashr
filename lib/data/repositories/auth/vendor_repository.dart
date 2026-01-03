import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/core/error/failures.dart';

/// Repository for managing Vendor (Farmer) data in Firestore.
class VendorRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('users');

  DatabaseFailure _handleFirebaseException(Object e) {
    if (e is FirebaseException) {
      return DatabaseFailure(
        e.message ?? 'A database error occurred',
        code: e.code,
      );
    }
    return DatabaseFailure(e.toString());
  }

  /// Stream of all vendors (users with userType == farmer)
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

  /// Get a vendor by ID
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

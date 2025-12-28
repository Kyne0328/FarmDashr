import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/user_profile.dart';

/// Repository for managing Vendor (Farmer) data in Firestore.
class VendorRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('users');

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
    final doc = await _collection.doc(vendorId).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!, doc.id);
    }
    return null;
  }
}

import 'package:farmdashr/data/models/auth/user_profile.dart';

/// Repository interface for managing Vendor (Farmer) data.
abstract class VendorRepository {
  /// Stream of all vendors (users with userType == farmer)
  Stream<List<UserProfile>> watchVendors();

  /// Get a vendor by ID
  Future<UserProfile?> getVendorById(String vendorId);
}

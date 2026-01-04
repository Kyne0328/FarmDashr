import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository interface for managing User Profile data.
abstract class UserRepository implements BaseRepository<UserProfile, String> {
  /// Get the current Firebase user
  User? get currentFirebaseUser;

  /// Get the current user's profile from Firestore
  Future<UserProfile?> getCurrentUserProfile();

  /// Update the current user's display name
  Future<void> updateDisplayName(String displayName);

  /// Switch user type
  Future<UserProfile?> switchUserType(UserType newType);

  /// Stream of current user's profile (real-time updates)
  Stream<UserProfile?> watchCurrentUser();

  /// Check if an email already exists in Firestore users collection
  Future<({String userId, bool hasGoogleProvider})?> checkEmailAndProviders(
    String email,
  );

  /// Add Google provider to user's providers list
  Future<void> addGoogleProvider(String userId);

  /// Sync providers from Firebase Auth to Firestore
  Future<void> syncProviders();

  /// Update user's FCM token
  Future<void> updateFcmToken(String userId, String? token);

  /// Add a pickup location to the user's business info
  Future<void> addPickupLocation(String userId, PickupLocation location);

  /// Remove a pickup location from the user's business info
  Future<void> removePickupLocation(String userId, PickupLocation location);
}

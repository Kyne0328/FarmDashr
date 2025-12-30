import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmdashr/data/models/user_profile.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository for managing User Profile data in Firestore.
/// Integrates with Firebase Auth for the current user.
class UserRepository implements BaseRepository<UserProfile, String> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('users');

  /// Get the current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Get the current user's profile from Firestore
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentFirebaseUser;
    if (user == null) return null;

    final doc = await _collection.doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!, doc.id);
    }

    // Create a default profile if none exists
    // Extract provider IDs from Firebase Auth to record in Firestore
    final providerIds = user.providerData
        .map((info) => info.providerId)
        .toList();

    final newProfile = UserProfile(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      userType: UserType.customer,
      memberSince: user.metadata.creationTime ?? DateTime.now(),
    );

    await create(newProfile);

    // Also record the providers list
    if (providerIds.isNotEmpty) {
      await _collection.doc(user.uid).update({'providers': providerIds});
    }

    return newProfile;
  }

  @override
  Future<List<UserProfile>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => UserProfile.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<UserProfile?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<UserProfile> create(UserProfile item) async {
    await _collection.doc(item.id).set(item.toJson());
    return item;
  }

  @override
  Future<UserProfile> update(UserProfile item) async {
    await _collection.doc(item.id).update(item.toJson());

    // Sync with Firebase Auth if updating the current user
    final user = _auth.currentUser;
    if (user != null && user.uid == item.id) {
      try {
        await user.updateDisplayName(item.name);
        if (item.profilePictureUrl != null) {
          await user.updatePhotoURL(item.profilePictureUrl);
        }
      } catch (e) {
        // Log error but don't fail the Firestore update
        debugPrint('Error syncing with Firebase Auth: $e');
      }
    }

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

  /// Update the current user's display name in both Firebase Auth and Firestore
  Future<void> updateDisplayName(String displayName) async {
    await currentFirebaseUser?.updateDisplayName(displayName);

    final userId = currentFirebaseUser?.uid;
    if (userId != null) {
      await _collection.doc(userId).update({'name': displayName});
    }
  }

  /// Switch user type (deprecated for view switching, use navigation instead)
  Future<UserProfile?> switchUserType(UserType newType) async {
    // Only allow switching TO farmer if not already one.
    // Switching BACK to customer is discouraged as it breaks vendor listing.
    final current = await getCurrentUserProfile();
    if (current != null && current.userType != newType) {
      final updated = current.copyWith(userType: newType);
      return update(updated);
    }
    return current;
  }

  /// Stream of current user's profile (real-time updates)
  Stream<UserProfile?> watchCurrentUser() {
    final userId = currentFirebaseUser?.uid;
    if (userId == null) return Stream.value(null);

    return _collection.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Check if an email already exists in Firestore users collection.
  /// Returns a record with userId and whether Google is already linked.
  /// Returns null if email doesn't exist.
  Future<({String userId, bool hasGoogleProvider})?> checkEmailAndProviders(
    String email,
  ) async {
    final snapshot = await _collection
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();
      final providers = (data['providers'] as List<dynamic>?) ?? [];
      final hasGoogle = providers.contains('google.com');
      return (userId: doc.id, hasGoogleProvider: hasGoogle);
    }
    return null;
  }

  /// Add Google provider to user's providers list in Firestore.
  /// Call this after successfully linking Google credential.
  Future<void> addGoogleProvider(String userId) async {
    await _collection.doc(userId).update({
      'providers': FieldValue.arrayUnion(['google.com']),
    });
  }

  /// Sync providers from Firebase Auth to Firestore.
  /// Call this on login to ensure Firestore's providers list is accurate.
  Future<void> syncProviders() async {
    final user = currentFirebaseUser;
    if (user == null) return;

    final providerIds = user.providerData
        .map((info) => info.providerId)
        .toList();
    if (providerIds.isNotEmpty) {
      await _collection.doc(user.uid).update({'providers': providerIds});
    }
  }
}

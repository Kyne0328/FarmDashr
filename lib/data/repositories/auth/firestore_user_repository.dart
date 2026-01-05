import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'user_repository.dart';

/// Firestore implementation of User Profile repository.
class FirestoreUserRepository implements UserRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreUserRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

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
  User? get currentFirebaseUser => _auth.currentUser;

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) return null;

      final doc = await _collection.doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!, doc.id);
      }

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

      if (providerIds.isNotEmpty) {
        await _collection.doc(user.uid).update({'providers': providerIds});
      }

      return newProfile;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<List<UserProfile>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<UserProfile?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<UserProfile> create(UserProfile item) async {
    try {
      await _collection.doc(item.id).set(item.toJson());
      return item;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<UserProfile> update(UserProfile item) async {
    try {
      await _collection.doc(item.id).update(item.toJson());

      final user = _auth.currentUser;
      if (user != null && user.uid == item.id) {
        try {
          await user.updateDisplayName(item.name);
          if (item.profilePictureUrl != null) {
            await user.updatePhotoURL(item.profilePictureUrl);
          }
        } catch (e) {
          debugPrint('Error syncing with Firebase Auth: $e');
        }
      }

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
  Future<void> updateDisplayName(String displayName) async {
    try {
      await currentFirebaseUser?.updateDisplayName(displayName);

      final userId = currentFirebaseUser?.uid;
      if (userId != null) {
        await _collection.doc(userId).update({'name': displayName});
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw AuthFailure.fromFirebase(e);
      }
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<UserProfile?> switchUserType(UserType newType) async {
    final current = await getCurrentUserProfile();
    if (current != null && current.userType != newType) {
      final updated = current.copyWith(userType: newType);
      return update(updated);
    }
    return current;
  }

  @override
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

  @override
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

  @override
  Future<void> addGoogleProvider(String userId) async {
    await _collection.doc(userId).update({
      'providers': FieldValue.arrayUnion(['google.com']),
    });
  }

  @override
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

  @override
  Future<void> updateFcmToken(String userId, String? token) async {
    try {
      await _collection.doc(userId).update({'fcmToken': token});
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<void> addPickupLocation(String userId, PickupLocation location) async {
    try {
      await _collection.doc(userId).update({
        'businessInfo.pickupLocations': FieldValue.arrayUnion([
          location.toJson(),
        ]),
      });
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<void> removePickupLocation(
    String userId,
    PickupLocation location,
  ) async {
    try {
      await _collection.doc(userId).update({
        'businessInfo.pickupLocations': FieldValue.arrayRemove([
          location.toJson(),
        ]),
      });
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<void> updatePickupLocation(
    String userId,
    PickupLocation oldLocation,
    PickupLocation newLocation,
  ) async {
    try {
      // Remove old location and add new one
      // Note: Ideally this should be a transaction, but array operations are atomic
      // and we just want to replace the item.
      final batch = _firestore.batch();
      final docRef = _collection.doc(userId);

      batch.update(docRef, {
        'businessInfo.pickupLocations': FieldValue.arrayRemove([
          oldLocation.toJson(),
        ]),
      });

      batch.update(docRef, {
        'businessInfo.pickupLocations': FieldValue.arrayUnion([
          newLocation.toJson(),
        ]),
      });

      await batch.commit();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }
}

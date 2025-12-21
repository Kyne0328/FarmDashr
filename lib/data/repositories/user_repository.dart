import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmdashr/data/models/user_profile.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository for managing User Profile data.
///
/// Integrates with Firebase Auth for the current user and
/// uses mock data for extended profile info.
class UserRepository implements BaseRepository<UserProfile, String> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-memory cache for demo purposes
  final Map<String, UserProfile> _profiles = {};

  /// Get the current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Get the current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentFirebaseUser;
    if (user == null) return null;

    // Check cache first
    if (_profiles.containsKey(user.uid)) {
      return _profiles[user.uid];
    }

    // Create a profile from Firebase user data
    final profile = UserProfile(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      userType: UserType.customer, // Default to customer
      memberSince: user.metadata.creationTime ?? DateTime.now(),
    );

    _profiles[user.uid] = profile;
    return profile;
  }

  @override
  Future<List<UserProfile>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _profiles.values.toList();
  }

  @override
  Future<UserProfile?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _profiles[id];
  }

  @override
  Future<UserProfile> create(UserProfile item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profiles[item.id] = item;
    return item;
  }

  @override
  Future<UserProfile> update(UserProfile item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profiles[item.id] = item;
    return item;
  }

  @override
  Future<bool> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_profiles.containsKey(id)) {
      _profiles.remove(id);
      return true;
    }
    return false;
  }

  /// Update the current user's display name
  Future<void> updateDisplayName(String displayName) async {
    await currentFirebaseUser?.updateDisplayName(displayName);

    final userId = currentFirebaseUser?.uid;
    if (userId != null && _profiles.containsKey(userId)) {
      _profiles[userId] = _profiles[userId]!.copyWith(name: displayName);
    }
  }

  /// Switch user type between farmer and customer
  Future<UserProfile?> switchUserType(UserType newType) async {
    final current = await getCurrentUserProfile();
    if (current != null) {
      final updated = current.copyWith(userType: newType);
      return update(updated);
    }
    return null;
  }
}

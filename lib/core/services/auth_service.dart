import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/core/error/failures.dart';

/// Service class that handles Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the currently signed-in user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes. Emits the user when signed in, null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is currently logged in.
  bool get isLoggedIn => _auth.currentUser != null;

  AuthFailure _handleAuthException(Object e) {
    if (e is FirebaseAuthException) {
      return AuthFailure.fromFirebase(e);
    }
    return AuthFailure(e.toString());
  }

  /// Sign up with email and password.
  ///
  /// Throws [AuthFailure] if registration fails.
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password.
  ///
  /// Throws [AuthFailure] if login fails.
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Links a credential (e.g. Google) to the currently signed-in user.
  /// This preserves the existing password provider while adding Google.
  ///
  /// Throws [AuthFailure] if linking fails.
  Future<UserCredential> linkProviderToAccount(
    AuthCredential credential,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(
        'No user is currently signed in to link the account to.',
        code: 'no-current-user',
      );
    }
    try {
      return await user.linkWithCredential(credential);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sends a password reset email to the given address.
  ///
  /// Throws [AuthFailure] if operation fails.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update the display name of the current user in both Firebase Auth and Firestore.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Update Firebase Auth profile
        await user.updateDisplayName(displayName);

        // Sync with Firestore users collection
        await _firestore.collection('users').doc(user.uid).set({
          'name': displayName,
          'email': user.email ?? '',
        }, SetOptions(merge: true));
      } catch (e) {
        if (e is FirebaseAuthException) {
          throw AuthFailure.fromFirebase(e);
        }
        throw DatabaseFailure(e.toString());
      }
    }
  }

  /// Re-authenticates the user with the provided password.
  ///
  /// Throws [AuthFailure] if re-authentication fails.
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        throw _handleAuthException(e);
      }
    }
  }

  /// Deletes the current user's account.
  ///
  /// Throws [AuthFailure] if the operation fails (e.g. requires recent login).
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } catch (e) {
        throw _handleAuthException(e);
      }
    }
  }

  /// Updates the password of the current user.
  ///
  /// Throws [AuthFailure] if the operation fails (e.g. requires recent login).
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updatePassword(newPassword);
      } catch (e) {
        throw _handleAuthException(e);
      }
    }
  }

  /// Links a password to the current user account.
  /// Used for users who signed up with social providers (like Google) and want to add a password.
  ///
  /// Throws [AuthFailure] if the operation fails.
  Future<void> linkPasswordToAccount(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(
        'No user is currently signed in.',
        code: 'no-current-user',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }
}

/// Converts a [Stream] into a [Listenable] for use with GoRouter's refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      // Use microtask to avoid "Build scheduled during build" errors
      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

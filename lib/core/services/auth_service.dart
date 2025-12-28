import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  /// Sign up with email and password.
  ///
  /// Throws [FirebaseAuthException] if registration fails.
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password.
  ///
  /// Throws [FirebaseAuthException] if login fails.
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Links a credential (e.g. Google) to the currently signed-in user.
  /// This preserves the existing password provider while adding Google.
  ///
  /// Throws [FirebaseAuthException] if linking fails.
  Future<UserCredential> linkProviderToAccount(
    AuthCredential credential,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in to link the account to.',
      );
    }
    return await user.linkWithCredential(credential);
  }

  /// Sends a password reset email to the given address.
  ///
  /// Throws [FirebaseAuthException] if operation fails.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update the display name of the current user in both Firebase Auth and Firestore.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);

      // Sync with Firestore users collection
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'name': displayName,
          'email': user.email ?? '',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error syncing display name to Firestore: $e');
      }
    }
  }

  /// Get a user-friendly error message from a FirebaseAuthException.
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'An error occurred. Please try again.';
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

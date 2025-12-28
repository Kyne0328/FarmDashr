import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Platform-safe GoogleSignIn initialization
  late final GoogleSignIn? _googleSignIn =
      (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
      ? GoogleSignIn(
          clientId: kIsWeb
              ? '232456469504-f8dmtrruei9t35nf6d8bep47f94m44l5.apps.googleusercontent.com'
              : null,
        )
      : null;

  /// Sign in with Google.
  ///
  /// Throws [FirebaseAuthException] or related errors if sign-in fails.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // For Web, use signInWithPopup as it's more reliable and handles idToken correctly.
      try {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } catch (e) {
        rethrow;
      }
    }

    if (_googleSignIn == null) {
      throw Exception('Google Sign-In is not supported on this platform.');
    }

    try {
      // Trigger the authentication flow for mobile/desktop
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from Google and Firebase.
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _auth.signOut();
  }

  /// Gets Google credential and email without signing in to Firebase.
  /// Returns a record with the credential and email, or null if cancelled.
  /// This is used on mobile to check for existing accounts before completing sign-in.
  Future<({AuthCredential credential, String email})?>
  getGoogleCredential() async {
    if (kIsWeb) {
      // Web doesn't support this flow, return null to use direct sign-in
      return null;
    }

    if (_googleSignIn == null) {
      throw Exception('Google Sign-In is not supported on this platform.');
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return (credential: credential, email: googleUser.email);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with an existing credential (used after linking flow).
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }
}

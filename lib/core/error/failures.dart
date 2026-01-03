import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.fromFirebase(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password is too weak. Use at least 6 characters.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-not-found':
        message = 'No account found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-credential':
        message = 'Invalid email or password. Please try again.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      default:
        message = e.message ?? 'Authentication failed. Please try again.';
    }
    return AuthFailure(message, code: e.code);
  }
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

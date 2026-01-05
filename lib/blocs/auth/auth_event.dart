import 'package:equatable/equatable.dart';

/// Base class for all authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check the current authentication status.
/// Should be dispatched when the app starts.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to sign in with email and password.
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign up with email, password, and name.
class AuthSignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

/// Event to sign in with Google.
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Event to sign out the current user.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to send a password reset email.
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// Event to update the user's display name.
class AuthUpdateDisplayNameRequested extends AuthEvent {
  final String displayName;

  const AuthUpdateDisplayNameRequested(this.displayName);

  @override
  List<Object?> get props => [displayName];
}

/// Event when the auth state changes externally (e.g., from Firebase).
class AuthStateChanged extends AuthEvent {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? profilePictureUrl;

  const AuthStateChanged({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.displayName,
    this.profilePictureUrl,
  });

  @override
  List<Object?> get props => [
    isAuthenticated,
    userId,
    email,
    displayName,
    profilePictureUrl,
  ];
}

/// Event to link Google credential to an existing email/password account.
class AuthLinkGoogleRequested extends AuthEvent {
  final String email;
  final String password;
  final dynamic googleCredential;
  final String userId;

  const AuthLinkGoogleRequested({
    required this.email,
    required this.password,
    required this.googleCredential,
    required this.userId,
  });

  @override
  List<Object?> get props => [email, password, googleCredential, userId];
}

/// Event to delete the user's account permanently.
class AuthDeleteAccountRequested extends AuthEvent {
  final String? password;

  const AuthDeleteAccountRequested({this.password});

  @override
  List<Object?> get props => [password];
}

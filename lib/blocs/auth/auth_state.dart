import 'package:equatable/equatable.dart';

/// Enum representing the authentication status.
enum AuthStatus {
  /// Initial state, auth status unknown.
  unknown,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

/// Base class for all authentication states.
abstract class AuthState extends Equatable {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? profilePictureUrl;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.userId,
    this.email,
    this.displayName,
    this.profilePictureUrl,
    this.errorMessage,
  });

  /// Whether the user is authenticated.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Whether the user is unauthenticated.
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Whether the auth status is unknown (initial/loading state).
  bool get isUnknown => status == AuthStatus.unknown;

  @override
  List<Object?> get props => [
    status,
    userId,
    email,
    displayName,
    profilePictureUrl,
    errorMessage,
  ];
}

/// Initial state when auth status is unknown.
class AuthInitial extends AuthState {
  const AuthInitial() : super(status: AuthStatus.unknown);
}

/// State while authentication is in progress.
class AuthLoading extends AuthState {
  const AuthLoading() : super(status: AuthStatus.unknown);
}

/// State when user is authenticated.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required super.userId,
    required super.email,
    super.displayName,
    super.profilePictureUrl,
  }) : super(status: AuthStatus.authenticated);

  @override
  List<Object?> get props => [
    status,
    userId,
    email,
    displayName,
    profilePictureUrl,
  ];
}

/// State when user is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({super.errorMessage})
    : super(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status, errorMessage];
}

/// State when an authentication error occurs.
class AuthError extends AuthState {
  const AuthError(String message)
    : super(status: AuthStatus.unauthenticated, errorMessage: message);

  @override
  List<Object?> get props => [status, errorMessage];
}

/// State when sign up is successful (before email verification if required).
class AuthSignUpSuccess extends AuthState {
  final String message;

  const AuthSignUpSuccess({
    required super.userId,
    required super.email,
    super.displayName,
    super.profilePictureUrl,
    this.message = 'Account created successfully!',
  }) : super(status: AuthStatus.authenticated);

  @override
  List<Object?> get props => [
    status,
    userId,
    email,
    displayName,
    profilePictureUrl,
    message,
  ];
}

/// State when password reset email is sent.
class AuthPasswordResetSent extends AuthState {
  final String resetEmail;

  const AuthPasswordResetSent(this.resetEmail)
    : super(status: AuthStatus.unauthenticated);

  String get message => 'Password reset email sent to $resetEmail';

  @override
  List<Object?> get props => [status, resetEmail];
}

/// State when Google sign-in finds an existing email that needs account linking.
class AuthGoogleLinkRequired extends AuthState {
  final String linkEmail;
  final dynamic googleCredential;
  final String existingUserId;

  const AuthGoogleLinkRequired({
    required this.linkEmail,
    required this.googleCredential,
    required this.existingUserId,
  }) : super(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [
    status,
    linkEmail,
    googleCredential,
    existingUserId,
  ];
}

/// State when re-authentication is required for a sensitive operation (like delete).
class AuthReauthRequired extends AuthState {
  const AuthReauthRequired() : super(status: AuthStatus.authenticated);

  @override
  List<Object?> get props => [status];
}

/// State when account is successfully deleted.
class AuthAccountDeleted extends AuthState {
  const AuthAccountDeleted() : super(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status];
}

/// State when password update is successful.
class AuthPasswordUpdateSuccess extends AuthState {
  const AuthPasswordUpdateSuccess() : super(status: AuthStatus.authenticated);

  @override
  List<Object?> get props => [status];
}

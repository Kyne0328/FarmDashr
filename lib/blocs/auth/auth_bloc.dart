import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmdashr/core/services/auth_service.dart';
import 'package:farmdashr/core/services/google_auth_service.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/data/repositories/product/product_repository.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'package:farmdashr/blocs/auth/auth_event.dart';
import 'package:farmdashr/blocs/auth/auth_state.dart';

/// BLoC for managing authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final GoogleAuthService _googleAuthService;
  final UserRepository _userRepository;
  final ProductRepository _productRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    required AuthService authService,
    required GoogleAuthService googleAuthService,
    required UserRepository userRepository,
    required ProductRepository productRepository,
  }) : _authService = authService,
       _googleAuthService = googleAuthService,
       _userRepository = userRepository,
       _productRepository = productRepository,
       super(const AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthLinkGoogleRequested>(_onLinkGoogleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthUpdateDisplayNameRequested>(_onUpdateDisplayNameRequested);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to Firebase auth state changes
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      add(
        AuthStateChanged(
          isAuthenticated: user != null,
          userId: user?.uid,
          email: user?.email,
          displayName: user?.displayName,
          profilePictureUrl: user?.photoURL,
        ),
      );
    });
  }

  /// Handle AuthCheckRequested event - check current auth status.
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final user = _authService.currentUser;
    if (user != null) {
      emit(
        AuthAuthenticated(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          profilePictureUrl: user.photoURL,
        ),
      );
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle AuthSignInRequested event - sign in with email/password.
  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userCredential = await _authService.signIn(
        event.email,
        event.password,
      );
      final user = userCredential.user;
      if (user != null) {
        emit(
          AuthAuthenticated(
            userId: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            profilePictureUrl: user.photoURL,
          ),
        );
      } else {
        emit(const AuthError('Sign in failed. Please try again.'));
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Sign in failed: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthSignUpRequested event - create new account.
  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final userCredential = await _authService.signUp(
        event.email,
        event.password,
      );
      final user = userCredential.user;
      if (user != null) {
        // Update display name
        await _authService.updateDisplayName(event.name);
        emit(
          AuthSignUpSuccess(
            userId: user.uid,
            email: user.email ?? '',
            displayName: event.name,
            profilePictureUrl: user.photoURL,
          ),
        );
      } else {
        emit(const AuthError('Sign up failed. Please try again.'));
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Sign up failed: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthGoogleSignInRequested event - sign in with Google.
  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Try to get Google credential without signing in (mobile only)
      final googleCredentialResult = await _googleAuthService
          .getGoogleCredential();

      if (googleCredentialResult != null) {
        // Mobile flow: check if email already exists
        final credential = googleCredentialResult.credential;
        final email = googleCredentialResult.email;

        // Check if this email exists in Firestore and if Google is already linked
        final emailCheck = await _userRepository.checkEmailAndProviders(email);

        if (emailCheck != null && !emailCheck.hasGoogleProvider) {
          // Email exists but Google not linked - emit state to show link dialog
          emit(
            AuthGoogleLinkRequired(
              linkEmail: email,
              googleCredential: credential,
              existingUserId: emailCheck.userId,
            ),
          );
          return;
        }

        // Either no existing account OR Google already linked - proceed
        await _googleAuthService.signInWithCredential(credential);
        await _userRepository.syncProviders();

        final user = _authService.currentUser;
        if (user != null) {
          emit(
            AuthAuthenticated(
              userId: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              profilePictureUrl: user.photoURL,
            ),
          );
        }
      } else {
        // Web flow or cancelled: use direct sign-in
        final userCredential = await _googleAuthService.signInWithGoogle();
        if (userCredential != null) {
          await _userRepository.syncProviders();
          final user = userCredential.user;
          if (user != null) {
            emit(
              AuthAuthenticated(
                userId: user.uid,
                email: user.email ?? '',
                displayName: user.displayName,
                profilePictureUrl: user.photoURL,
              ),
            );
          } else {
            emit(const AuthError('Google sign in failed. Please try again.'));
          }
        } else {
          // User cancelled the sign-in
          emit(const AuthUnauthenticated());
        }
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Google sign in failed: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthLinkGoogleRequested event - link Google to existing account.
  Future<void> _onLinkGoogleRequested(
    AuthLinkGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Step 1: Sign in with email/password first
      await _authService.signIn(event.email, event.password);

      // Step 2: Link the Google credential to preserve both providers
      await _authService.linkProviderToAccount(
        event.googleCredential as AuthCredential,
      );

      // Step 3: Record that Google is now linked in Firestore
      await _userRepository.addGoogleProvider(event.userId);

      final user = _authService.currentUser;
      if (user != null) {
        emit(
          AuthAuthenticated(
            userId: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            profilePictureUrl: user.photoURL,
          ),
        );
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Account linking failed: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthSignOutRequested event - sign out user.
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.signOut();
      await _googleAuthService.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Sign out failed: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthPasswordResetRequested event - send password reset email.
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: event.email);
      emit(AuthPasswordResetSent(event.email));
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Password reset failed: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthUpdateDisplayNameRequested event - update display name.
  Future<void> _onUpdateDisplayNameRequested(
    AuthUpdateDisplayNameRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.updateDisplayName(event.displayName);
      final user = _authService.currentUser;
      if (user != null) {
        emit(
          AuthAuthenticated(
            userId: user.uid,
            email: user.email ?? '',
            displayName: event.displayName,
          ),
        );
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Failed to update display name: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthDeleteAccountRequested event - delete account.
  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // 1. Re-authenticate if password provided
        if (event.password != null) {
          try {
            await _authService.reauthenticateWithPassword(event.password!);
          } catch (e) {
            emit(
              AuthError(e is Failure ? e.message : 'Authentication failed: $e'),
            );
            return;
          }
        }

        // 2. Delete Firestore data (Cascading delete)
        // First, delete products (if any)
        await _productRepository.deleteByFarmerId(user.uid);
        // Then delete the user profile
        await _userRepository.delete(user.uid);

        // 3. Delete Auth account
        try {
          await _authService.deleteAccount();
          emit(const AuthAccountDeleted());
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
            // Signal UI to request re-authentication (without creating a zombie state)
            emit(const AuthReauthRequired());
            return;
          }

          // Fallback: If other error, sign out to prevent zombie state.
          await _authService.signOut();
          final message = e is Failure
              ? e.message
              : 'Account deletion incomplete. Signed out for safety.';
          emit(AuthError(message));
        }
      }
    } catch (e) {
      final message = e is Failure
          ? e.message
          : 'Delete account failed: ${e.toString()}';
      emit(AuthError(message));
    }
  }

  /// Handle AuthStateChanged event - respond to Firebase auth state changes.
  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.isAuthenticated && event.userId != null) {
      emit(
        AuthAuthenticated(
          userId: event.userId!,
          email: event.email ?? '',
          displayName: event.displayName,
          profilePictureUrl: event.profilePictureUrl,
        ),
      );
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmdashr/core/services/auth_service.dart';
import 'package:farmdashr/core/services/google_auth_service.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/blocs/auth/auth_event.dart';
import 'package:farmdashr/blocs/auth/auth_state.dart';

/// BLoC for managing authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final GoogleAuthService _googleAuthService;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    AuthService? authService,
    GoogleAuthService? googleAuthService,
    UserRepository? userRepository,
  }) : _authService = authService ?? AuthService(),
       _googleAuthService = googleAuthService ?? GoogleAuthService(),
       _userRepository = userRepository ?? UserRepository(),
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
    } on FirebaseAuthException catch (e) {
      emit(AuthError(AuthService.getErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Sign in failed: ${e.toString()}'));
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
    } on FirebaseAuthException catch (e) {
      emit(AuthError(AuthService.getErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Sign up failed: ${e.toString()}'));
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
    } on FirebaseAuthException catch (e) {
      emit(AuthError(AuthService.getErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Google sign in failed: ${e.toString()}'));
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
    } on FirebaseAuthException catch (e) {
      emit(AuthError(AuthService.getErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Account linking failed: ${e.toString()}'));
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
      emit(AuthError('Sign out failed: ${e.toString()}'));
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
    } on FirebaseAuthException catch (e) {
      emit(AuthError(AuthService.getErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Password reset failed: ${e.toString()}'));
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
      emit(AuthError('Failed to update display name: ${e.toString()}'));
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

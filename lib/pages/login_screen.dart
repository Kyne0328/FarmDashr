import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/auth_service.dart';
import 'package:farmdashr/core/services/google_auth_service.dart';
import 'package:farmdashr/data/repositories/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _googleAuthService = GoogleAuthService();
  final _userRepository = UserRepository();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingL),
                _buildBackButton(),
                const SizedBox(height: AppDimensions.spacingXL),
                _buildLoginCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_back,
            size: AppDimensions.iconM,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            'Back',
            style: AppTextStyles.body1.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: AppDimensions.spacingXXL),
          _buildInputFields(),
          const SizedBox(height: AppDimensions.spacingM),
          _buildForgotPasswordLink(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildLoginButton(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildDivider(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildSocialLoginButtons(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildSignUpLink(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: AppDimensions.avatarM + 4,
          height: AppDimensions.avatarM + 4,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/leaf_icon.svg',
              width: AppDimensions.iconL + 8,
              height: AppDimensions.iconL + 8,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        Text(
          'Welcome Back',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text('Log in to your account', style: AppTextStyles.body2Secondary),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _buildTextField(
          label: 'Email',
          hint: 'you@example.com',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          label: 'Password',
          hint: '••••••••',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: AppDimensions.iconM,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body2Tertiary),
        const SizedBox(height: AppDimensions.spacingS),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTextStyles.body1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.textSecondary,
              size: AppDimensions.iconM,
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingXL,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => context.go('/forgot-password'),
        child: Text('Forgot password?', style: AppTextStyles.link),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightLarge,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: AppDimensions.iconM,
                height: AppDimensions.iconM,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Log In',
                style: AppTextStyles.button.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
          ),
          child: Text('Or continue with', style: AppTextStyles.body2Secondary),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return _buildSocialButton(
      label: 'Continue with Google',
      iconPath: 'assets/sign_up/assets/Google.svg',
      onTap: _handleGoogleSignIn,
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightLarge,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: AppDimensions.iconM,
              height: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Text(
              label,
              style: AppTextStyles.body1.copyWith(color: AppColors.completed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: AppTextStyles.body2Tertiary),
        GestureDetector(
          onTap: () => context.go('/signup'),
          child: Text(
            'Sign up',
            style: AppTextStyles.link.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email, password);
      if (mounted && context.mounted) {
        context.go('/customer-home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

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
          // Email exists but Google not linked! Prompt user to link accounts
          if (mounted && context.mounted) {
            setState(() => _isLoading = false);
            await _showLinkAccountDialog(email, credential, emailCheck.userId);
          }
          return;
        }

        // Either no existing account OR Google already linked - proceed with Google sign-in

        // No existing account, proceed with Google sign-in
        await _googleAuthService.signInWithCredential(credential);
        if (mounted && context.mounted) {
          context.go('/customer-home');
        }
      } else {
        // Web flow or cancelled: use direct sign-in
        final userCredential = await _googleAuthService.signInWithGoogle();
        if (userCredential != null && mounted && context.mounted) {
          context.go('/customer-home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLinkAccountDialog(
    String email,
    AuthCredential googleCredential,
    String userId,
  ) async {
    final passwordController = TextEditingController();
    bool isLinking = false;
    bool obscurePassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Link Your Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'An account with $email already exists.',
                  style: AppTextStyles.body2Secondary,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'Enter your password to link Google Sign-In to your existing account.',
                  style: AppTextStyles.body2Secondary,
                ),
                const SizedBox(height: AppDimensions.spacingL),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(
                          () => obscurePassword = !obscurePassword,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLinking
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLinking
                    ? null
                    : () async {
                        final password = passwordController.text;
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your password'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isLinking = true);

                        try {
                          // Step 1: Sign in with email/password first
                          await _authService.signIn(email, password);

                          // Step 2: Link the Google credential to preserve both providers
                          await _authService.linkProviderToAccount(
                            googleCredential,
                          );

                          // Step 3: Record that Google is now linked in Firestore
                          await _userRepository.addGoogleProvider(userId);

                          if (mounted && dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            context.go('/customer-home');
                          }
                        } on FirebaseAuthException catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(AuthService.getErrorMessage(e)),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setDialogState(() => isLinking = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: isLinking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Link Account',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

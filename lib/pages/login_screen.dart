import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';

import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthSignUpSuccess) {
          context.go('/customer-home');
        } else if (state is AuthError) {
          SnackbarHelper.showError(
            context,
            state.errorMessage ?? 'An error occurred',
          );
        } else if (state is AuthGoogleLinkRequired) {
          _showLinkAccountDialog(
            state.linkEmail,
            state.googleCredential as AuthCredential,
            state.existingUserId,
          );
        }
      },
      child: Scaffold(
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          FarmTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FarmTextField(
            label: 'Password',
            hint: '••••••••',
            controller: _passwordController,
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: _obscurePassword,
            validator: Validators.validateRequired,
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
      ),
    );
  }

  // Removed _buildTextField helper as it's replaced by FarmTextField

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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return FarmButton(
          label: 'Log In',
          isLoading: isLoading,
          onPressed: _handleLogin,
          style: FarmButtonStyle.primary,
        );
      },
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

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    context.read<AuthBloc>().add(
      AuthSignInRequested(email: email, password: password),
    );
  }

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  Future<void> _showLinkAccountDialog(
    String email,
    AuthCredential googleCredential,
    String userId,
  ) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                Navigator.pop(dialogContext);
              } else if (state is AuthError) {
                SnackbarHelper.showError(
                  dialogContext,
                  state.errorMessage ?? 'An error occurred',
                );
              }
            },
            builder: (context, state) {
              final isLinking = state is AuthLoading;
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
                        : () {
                            final password = passwordController.text;
                            if (password.isEmpty) {
                              SnackbarHelper.showError(
                                dialogContext,
                                'Please enter your password',
                              );
                              return;
                            }

                            context.read<AuthBloc>().add(
                              AuthLinkGoogleRequested(
                                email: email,
                                password: password,
                                googleCredential: googleCredential,
                                userId: userId,
                              ),
                            );
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
                            style: AppTextStyles.button,
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: AppColors.error,
            ),
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
                  _buildSignUpCard(),
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
      onTap: () => context.go('/login'),
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

  Widget _buildSignUpCard() {
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
          const SizedBox(height: AppDimensions.spacingXL),
          _buildCreateAccountButton(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildDivider(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildSocialLoginButtons(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildLoginLink(),
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
            child: Image.asset(
              'assets/app_icon.png',
              width: AppDimensions.iconL + 8,
              height: AppDimensions.iconL + 8,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        Text(
          'Create Account',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text('Join Fresh Market today', style: AppTextStyles.body2Secondary),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _buildTextField(
          label: 'Full Name',
          hint: 'John Doe',
          controller: _fullNameController,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: AppDimensions.spacingL),
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, size: AppDimensions.iconM),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightLarge,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleSignUp,
            child: isLoading
                ? SizedBox(
                    width: AppDimensions.iconM,
                    height: AppDimensions.iconM,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: AppTextStyles.button.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account? ", style: AppTextStyles.body2Tertiary),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            'Log in',
            style: AppTextStyles.link.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _handleSignUp() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthSignUpRequested(name: fullName, email: email, password: password),
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
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'An error occurred'),
                    backgroundColor: AppColors.error,
                  ),
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
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your password'),
                                  backgroundColor: AppColors.error,
                                ),
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

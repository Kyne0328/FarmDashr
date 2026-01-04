import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/auth_service.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/core/utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
                _buildForgotPasswordCard(),
              ],
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

  Widget _buildForgotPasswordCard() {
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
          _buildEmailField(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildResetButton(),
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
          'Forgot Password',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Enter your email to receive a password reset link',
          style: AppTextStyles.body2Secondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Form(
      key: _formKey,
      child: FarmTextField(
        controller: _emailController,
        label: 'Email',
        hint: 'you@example.com',
        keyboardType: TextInputType.emailAddress,
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.textSecondary,
          size: AppDimensions.iconM,
        ),
        validator: Validators.validateEmail,
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: FarmButton(
        label: 'Send Reset Link',
        onPressed: _isLoading ? null : _handleResetPassword,
        style: FarmButtonStyle.primary,
        isLoading: _isLoading,
        height: AppDimensions.buttonHeightLarge,
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    try {
      await _authService.resetPassword(email);
      if (mounted && context.mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Password reset email sent! Check your inbox.',
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted && context.mounted) {
        final message = e is Failure ? e.message : 'Error: ${e.toString()}';
        SnackbarHelper.showError(context, message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

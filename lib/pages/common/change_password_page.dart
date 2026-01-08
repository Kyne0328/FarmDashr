import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/core/utils/validators.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/core/utils/responsive.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthUpdatePasswordRequested(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordUpdateSuccess) {
            SnackbarHelper.showSuccess(
              context,
              'Password updated successfully',
            );
            context.pop();
          } else if (state is AuthError) {
            SnackbarHelper.showError(
              context,
              state.errorMessage ?? 'Failed to update password',
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.maxContentWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    Responsive.horizontalPadding(context),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Security', style: AppTextStyles.h3),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          'Set a strong password to protect your account.',
                          style: AppTextStyles.body2Secondary,
                        ),
                        const SizedBox(height: AppDimensions.spacingXL),

                        FarmTextField(
                          label: 'Current Password',
                          hint: 'Enter your current password',
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent,
                            ),
                          ),
                          validator: Validators.validateRequired,
                        ),
                        const SizedBox(height: AppDimensions.spacingL),

                        FarmTextField(
                          label: 'New Password',
                          hint: 'Enter new password',
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: AppDimensions.spacingL),

                        FarmTextField(
                          label: 'Confirm New Password',
                          hint: 'Confirm your new password',
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingXXL),

                        FarmButton(
                          label: 'Update Password',
                          onPressed: isLoading ? null : _handleSubmit,
                          isLoading: isLoading,
                          style: FarmButtonStyle.primary,
                          isFullWidth: true,
                          height: 56,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

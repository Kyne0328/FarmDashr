import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/common/step_indicator.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/core/utils/validators.dart';

class CustomerOnboardingPage extends StatefulWidget {
  const CustomerOnboardingPage({super.key});

  @override
  State<CustomerOnboardingPage> createState() => _CustomerOnboardingPageState();
}

class _CustomerOnboardingPageState extends State<CustomerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+63 ');
  final _addressController = TextEditingController();
  final _userRepo = FirestoreUserRepository();
  bool _isLoading = false;
  int _currentStep = 0;

  static const List<String> _stepLabels = ['Personal Info', 'Confirm'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final currentProfile = await _userRepo.getCurrentUserProfile();
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );
        await _userRepo.update(updatedProfile);
        if (mounted && context.mounted) {
          context.go('/customer-home');
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    HapticService.selection();
    if (_currentStep == 0) {
      // Validate personal info
      if (_nameController.text.trim().isEmpty) {
        SnackbarHelper.showError(context, 'Please enter your name');
        return;
      }
      final phoneError = Validators.validatePhilippinesPhone(
        _phoneController.text,
      );
      if (phoneError != null) {
        SnackbarHelper.showError(context, phoneError);
        return;
      }
    }

    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    HapticService.selection();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingXL),
                _buildHeader(),
                const SizedBox(height: AppDimensions.spacingL),
                StepIndicator(
                  currentStep: _currentStep,
                  totalSteps: 2,
                  stepLabels: _stepLabels,
                ),
                const SizedBox(height: AppDimensions.spacingXL),
                _buildStepContent(),
                const SizedBox(height: 40),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/app_icon.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        Text(
          'Welcome to FarmDashR!',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'Let\'s set up your profile to get started',
          style: AppTextStyles.body2Secondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildConfirmStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'This information helps farmers contact you about your orders',
          style: AppTextStyles.body2Secondary,
        ),
        const SizedBox(height: 24),
        FarmTextField(
          label: 'Full Name',
          hint: 'e.g. Juan Dela Cruz',
          controller: _nameController,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: 20),
        FarmTextField(
          label: 'Phone Number',
          hint: 'e.g. +63 912 345 6789',
          controller: _phoneController,
          prefixIcon: const Icon(Icons.phone_outlined),
          validator: Validators.validatePhilippinesPhone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        FarmTextField(
          label: 'Address (Optional)',
          hint: 'e.g. 123 Main St, Quezon City',
          controller: _addressController,
          prefixIcon: const Icon(Icons.location_on_outlined),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Profile',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure your information is correct',
          style: AppTextStyles.body2Secondary,
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(
            icon: Icons.person_outlined,
            label: 'Name',
            value: _nameController.text.trim().isEmpty
                ? 'Not provided'
                : _nameController.text.trim(),
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _phoneController.text.trim() == '+63'
                ? 'Not provided'
                : _phoneController.text.trim(),
          ),
          if (_addressController.text.trim().isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: _addressController.text.trim(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.cardCaption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: FarmButton(
              label: 'Back',
              onPressed: _previousStep,
              style: FarmButtonStyle.outline,
              isFullWidth: true,
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: FarmButton(
            label: _currentStep == 1 ? 'Complete Setup' : 'Continue',
            onPressed: _isLoading ? null : _nextStep,
            isLoading: _isLoading,
            style: FarmButtonStyle.primary,
            backgroundColor: AppColors.primary,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}

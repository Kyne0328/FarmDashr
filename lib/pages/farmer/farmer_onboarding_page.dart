import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/common/step_indicator.dart';

class FarmerOnboardingPage extends StatefulWidget {
  const FarmerOnboardingPage({super.key});

  @override
  State<FarmerOnboardingPage> createState() => _FarmerOnboardingPageState();
}

class _FarmerOnboardingPageState extends State<FarmerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController(text: '+63 ');
  final _userRepo = UserRepository();
  bool _isLoading = false;
  int _currentStep = 0;

  static const List<String> _stepLabels = ['Farm Info', 'Contact', 'Confirm'];

  @override
  void dispose() {
    _farmNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final currentProfile = await _userRepo.getCurrentUserProfile();
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          userType: UserType.farmer,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          businessInfo: BusinessInfo(
            farmName: _farmNameController.text.trim(),
            vendorSince: DateTime.now(),
          ),
        );
        await _userRepo.update(updatedProfile);
        if (mounted && context.mounted) {
          context.go('/farmer-home-page');
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
    if (_currentStep == 0) {
      // Validate farm name
      if (_farmNameController.text.trim().isEmpty) {
        SnackbarHelper.showError(context, 'Please enter your farm name');
        return;
      }
    } else if (_currentStep == 1) {
      // Validate address and phone
      if (_addressController.text.trim().isEmpty) {
        SnackbarHelper.showError(context, 'Please enter your farm address');
        return;
      }
      if (_phoneController.text.trim() == '+63' ||
          _phoneController.text.trim().isEmpty) {
        SnackbarHelper.showError(context, 'Please enter your phone number');
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farmer Registration'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepIndicator(
                  currentStep: _currentStep,
                  totalSteps: 3,
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildFarmInfoStep();
      case 1:
        return _buildContactStep();
      case 2:
        return _buildConfirmStep();
      default:
        return _buildFarmInfoStep();
    }
  }

  Widget _buildFarmInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your farm',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps customers identify your products',
          style: AppTextStyles.body2Secondary,
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Farm Name',
          hint: 'e.g. Green Valley Farm',
          controller: _farmNameController,
          validator: (value) =>
              value == null || value.isEmpty ? 'Please enter farm name' : null,
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'How can customers reach you?',
          style: AppTextStyles.body2Secondary,
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Farm Address',
          hint: 'e.g. 123 Farm Road, City',
          controller: _addressController,
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter farm address'
              : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Phone Number',
          hint: 'e.g. 912 345 6789',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value == null || value.isEmpty || value.trim() == '+63'
              ? 'Please enter phone number'
              : null,
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Details',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure everything looks good',
          style: AppTextStyles.body2Secondary,
        ),
        const SizedBox(height: 32),
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
            icon: Icons.store_outlined,
            label: 'Farm Name',
            value: _farmNameController.text.trim().isEmpty
                ? 'Not provided'
                : _farmNameController.text.trim(),
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _addressController.text.trim().isEmpty
                ? 'Not provided'
                : _addressController.text.trim(),
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _phoneController.text.trim() == '+63'
                ? 'Not provided'
                : _phoneController.text.trim(),
          ),
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
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentStep == 2 ? 'Complete Registration' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

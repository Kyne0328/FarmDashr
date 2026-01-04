import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
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

  // Step 1: Farm Info
  final _farmNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Step 2: Contact
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController(text: '+63 ');

  // Step 3: Business Details
  final _licenseController = TextEditingController();
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  final Set<int> _operatingDays = {}; // 1 = Mon, 7 = Sun

  // Step 4: Social & Certs
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final List<Certification> _certifications = [];

  final _userRepo = UserRepository();
  bool _isLoading = false;
  int _currentStep = 0;

  static const List<String> _stepLabels = [
    'Farm Info',
    'Contact',
    'Business',
    'Social',
    'Confirm',
  ];

  @override
  void dispose() {
    _farmNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  String _formatOperatingHours() {
    if (_operatingDays.isEmpty || _openTime == null || _closeTime == null) {
      return '';
    }

    final sortedDays = _operatingDays.toList()..sort();
    final dayNames = sortedDays.map(_getDayShortName).join(', ');
    final openStr = _formatTime(_openTime!);
    final closeStr = _formatTime(_closeTime!);

    return '$dayNames: $openStr - $closeStr';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getDayShortName(int day) {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final currentProfile = await _userRepo.getCurrentUserProfile();
      if (currentProfile != null) {
        final businessInfo = BusinessInfo(
          farmName: _farmNameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          businessLicense: _licenseController.text.trim().isNotEmpty
              ? _licenseController.text.trim()
              : null,
          operatingHours: _formatOperatingHours().isNotEmpty
              ? _formatOperatingHours()
              : null,
          facebookUrl: _facebookController.text.trim().isNotEmpty
              ? _facebookController.text.trim()
              : null,
          instagramUrl: _instagramController.text.trim().isNotEmpty
              ? _instagramController.text.trim()
              : null,
          certifications: _certifications,
          vendorSince: DateTime.now(),
        );

        final updatedProfile = currentProfile.copyWith(
          userType: UserType.farmer,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          businessInfo: businessInfo,
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
    HapticService.selection();

    if (_currentStep == 0) {
      if (_farmNameController.text.trim().isEmpty) {
        SnackbarHelper.showError(context, 'Please enter your farm name');
        return;
      }
    } else if (_currentStep == 1) {
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
    // Steps 2, 3 are optional

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    HapticService.selection();
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
                vertical: AppDimensions.paddingM,
              ),
              child: StepIndicator(
                currentStep: _currentStep,
                totalSteps: 5,
                stepLabels: _stepLabels,
                activeColor: AppColors.farmerPrimary,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(key: _formKey, child: _buildStepContent()),
              ),
            ),
            _buildNavigationButtons(),
          ],
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
        return _buildBusinessStep();
      case 3:
        return _buildSocialCertsStep();
      case 4:
        return _buildConfirmStep();
      default:
        return _buildFarmInfoStep();
    }
  }

  Widget _buildFarmInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.storefront_outlined,
          title: 'Tell us about your farm',
          subtitle: 'This helps customers identify your products',
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Farm Name *',
          hint: 'e.g. Green Valley Farm',
          controller: _farmNameController,
          prefixIcon: Icons.store_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Description',
          hint: 'Tell customers about your farm story...',
          controller: _descriptionController,
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.contact_phone_outlined,
          title: 'Contact Information',
          subtitle: 'How can customers reach you?',
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Farm Address *',
          hint: 'e.g. 123 Farm Road, City',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Phone Number *',
          hint: 'e.g. 912 345 6789',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildBusinessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.business_outlined,
          title: 'Business Details',
          subtitle: 'Optional but helps build trust',
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'Business License',
          hint: 'e.g. BUS-2024-12345',
          controller: _licenseController,
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 24),
        _buildOperatingHoursSection(),
      ],
    );
  }

  Widget _buildOperatingHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operating Hours',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the days and times you\'re available',
          style: AppTextStyles.body2Secondary,
        ),
        const SizedBox(height: 16),

        // Day selector
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isSelected = _operatingDays.contains(day);
            return GestureDetector(
              onTap: () {
                HapticService.selection();
                setState(() {
                  if (isSelected) {
                    _operatingDays.remove(day);
                  } else {
                    _operatingDays.add(day);
                  }
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.farmerPrimary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.farmerPrimary
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getDayLetter(day),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Time pickers
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                label: 'Opens',
                time: _openTime,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _openTime ?? const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => _openTime = picked);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimePicker(
                label: 'Closes',
                time: _closeTime,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _closeTime ?? const TimeOfDay(hour: 17, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => _closeTime = picked);
                  }
                },
              ),
            ),
          ],
        ),

        if (_formatOperatingHours().isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.farmerPrimaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppColors.farmerPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatOperatingHours(),
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.farmerPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    time != null ? _formatTime(time) : 'Select time',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w500,
                      color: time != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayLetter(int day) {
    switch (day) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }

  Widget _buildSocialCertsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.share_outlined,
          title: 'Social & Certifications',
          subtitle: 'Connect with customers and showcase your credentials',
        ),
        const SizedBox(height: 32),

        // Social Media Section
        Text(
          'Social Media',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Facebook',
          hint: 'https://facebook.com/yourfarm',
          controller: _facebookController,
          prefixIcon: Icons.facebook,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Instagram',
          hint: 'https://instagram.com/yourfarm',
          controller: _instagramController,
          prefixIcon: Icons.camera_alt_outlined,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 32),

        // Certifications Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Certifications',
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _showAddCertificationDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.farmerPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_certifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: AppColors.textTertiary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add certifications like Organic, Fair Trade, etc.',
                    style: AppTextStyles.body2Secondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_certifications.map(_buildCertificationTile)),
      ],
    );
  }

  Widget _buildCertificationTile(Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            _getCertificationIcon(cert.type),
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cert.name,
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() => _certifications.remove(cert));
            },
          ),
        ],
      ),
    );
  }

  IconData _getCertificationIcon(CertificationType type) {
    switch (type) {
      case CertificationType.organic:
        return Icons.eco;
      case CertificationType.local:
        return Icons.location_on;
      case CertificationType.nonGmo:
        return Icons.science;
      case CertificationType.fairTrade:
        return Icons.handshake;
      case CertificationType.other:
        return Icons.verified;
    }
  }

  void _showAddCertificationDialog() {
    final nameController = TextEditingController();
    CertificationType selectedType = CertificationType.organic;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          title: Text('Add Certification', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Certification Name',
                  hintText: 'e.g. USDA Organic',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Text('Type', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppDimensions.spacingS),
              DropdownButtonFormField<CertificationType>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                items: CertificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getCertificationTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _certifications.add(
                      Certification(
                        name: nameController.text.trim(),
                        type: selectedType,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.farmerPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCertificationTypeLabel(CertificationType type) {
    switch (type) {
      case CertificationType.organic:
        return 'Organic';
      case CertificationType.local:
        return 'Locally Sourced';
      case CertificationType.nonGmo:
        return 'Non-GMO';
      case CertificationType.fairTrade:
        return 'Fair Trade';
      case CertificationType.other:
        return 'Other';
    }
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.checklist_rounded,
          title: 'Review Your Details',
          subtitle: 'Make sure everything looks good',
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
          if (_descriptionController.text.trim().isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.description_outlined,
              label: 'Description',
              value: _descriptionController.text.trim(),
            ),
          ],
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
          if (_licenseController.text.trim().isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.badge_outlined,
              label: 'License',
              value: _licenseController.text.trim(),
            ),
          ],
          if (_formatOperatingHours().isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.schedule_outlined,
              label: 'Hours',
              value: _formatOperatingHours(),
            ),
          ],
          if (_facebookController.text.trim().isNotEmpty ||
              _instagramController.text.trim().isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.share_outlined,
              label: 'Social',
              value: [
                if (_facebookController.text.trim().isNotEmpty) 'Facebook',
                if (_instagramController.text.trim().isNotEmpty) 'Instagram',
              ].join(', '),
            ),
          ],
          if (_certifications.isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.verified_outlined,
              label: 'Certifications',
              value: _certifications.map((c) => c.name).join(', '),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.farmerPrimaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.farmerPrimary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.farmerPrimaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.farmerPrimary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.body2Secondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
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
                  backgroundColor: AppColors.farmerPrimary,
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
                        _currentStep == 4
                            ? 'Complete Registration'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body2.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
                : null,
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
              borderSide: const BorderSide(
                color: AppColors.farmerPrimary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';

import 'package:farmdashr/presentation/widgets/common/step_indicator.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';

class BusinessInfoPage extends StatefulWidget {
  const BusinessInfoPage({super.key});

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepo = UserRepository();

  late TextEditingController _farmNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _licenseController;
  late TextEditingController _hoursController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userRepo.getCurrentUserProfile();
      if (mounted && profile != null) {
        setState(() {
          _userProfile = profile;
          final businessInfo = profile.businessInfo;
          if (businessInfo != null) {
            _farmNameController.text = businessInfo.farmName;
            _descriptionController.text = businessInfo.description ?? '';
            _licenseController.text = businessInfo.businessLicense ?? '';
            _hoursController.text = businessInfo.operatingHours ?? '';
            _facebookController.text = businessInfo.facebookUrl ?? '';
            _instagramController.text = businessInfo.instagramUrl ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error loading profile: $e');
      }
    }
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userProfile == null) return;

    setState(() => _isSaving = true);
    try {
      // Fetch latest profile to avoid overwriting concurrent changes
      final latestProfile = await _userRepo.getById(_userProfile!.id);
      if (latestProfile == null) throw Exception('User profile not found');

      final updatedBusinessInfo = BusinessInfo(
        farmName: _farmNameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        businessLicense: _licenseController.text.trim().isNotEmpty
            ? _licenseController.text.trim()
            : null,
        operatingHours: _hoursController.text.trim().isNotEmpty
            ? _hoursController.text.trim()
            : null,
        facebookUrl: _facebookController.text.trim().isNotEmpty
            ? _facebookController.text.trim()
            : null,
        instagramUrl: _instagramController.text.trim().isNotEmpty
            ? _instagramController.text.trim()
            : null,
        pickupLocations: _userProfile?.businessInfo?.pickupLocations ?? [],
        // Use local certifications as they are updated in state
        certifications: _userProfile?.businessInfo?.certifications ?? [],
        // Preserve the original vendor since timestamp
        vendorSince: _userProfile?.businessInfo?.vendorSince,
      );

      final updatedProfile = latestProfile.copyWith(
        businessInfo: updatedBusinessInfo,
      );

      await _userRepo.update(updatedProfile);

      if (mounted) {
        setState(() {
          _userProfile = updatedProfile;
          _isSaving = false;
        });
        SnackbarHelper.showSuccess(
          context,
          'Business information saved successfully!',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(context, 'Failed to save: $e');
      }
    }
  }

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<String> _stepLabels = ['Details', 'Operations', 'Social & Certs'];

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _licenseController = TextEditingController();
    _hoursController = TextEditingController();
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _farmNameController.dispose();
    _descriptionController.dispose();
    _licenseController.dispose();
    _hoursController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      // Validate current step
      if (_currentStep == 0) {
        if (_farmNameController.text.trim().isEmpty) {
          SnackbarHelper.showError(context, 'Farm Name is required.');
          return;
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveBusinessInfo();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _previousStep,
        ),
        title: Text(
          'Business Information',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                  ),
                  child: StepIndicator(
                    currentStep: _currentStep,
                    totalSteps: 3,
                    stepLabels: _stepLabels,
                    activeColor: AppColors.farmerPrimary,
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildDetailsStep(),
                        _buildOperationsStep(),
                        _buildSocialCertsStep(),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.storefront_outlined,
            title: 'Farm Details',
            subtitle: 'Basic information about your farm',
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildCard(
            children: [
              _buildTextField(
                label: 'Farm Name *',
                hint: 'e.g. Green Valley Farm',
                controller: _farmNameController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildTextField(
                label: 'Description',
                hint: 'Tell customers about your farm story...',
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildTextField(
                label: 'Business License',
                hint: 'e.g. BUS-2024-12345',
                controller: _licenseController,
                prefixIcon: Icons.badge_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.schedule_outlined,
            title: 'Operating Hours',
            subtitle: 'When customers can reach you',
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildCard(
            children: [
              _buildTextField(
                label: 'Hours',
                hint: 'e.g. Mon-Sat: 8AM-5PM',
                controller: _hoursController,
                prefixIcon: Icons.access_time,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildPickupLocationsSection(),
        ],
      ),
    );
  }

  Widget _buildSocialCertsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.share_outlined,
            title: 'Social Media',
            subtitle: 'Connect with your customers online',
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildCard(
            children: [
              _buildTextField(
                label: 'Facebook',
                hint: 'https://facebook.com/yourfarm',
                controller: _facebookController,
                prefixIcon: Icons.facebook,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildTextField(
                label: 'Instagram',
                hint: 'https://instagram.com/yourfarm',
                controller: _instagramController,
                prefixIcon: Icons.camera_alt_outlined,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildCertificationsSection(),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
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
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.farmerPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 2 ? 'Save Information' : 'Continue',
                        style: AppTextStyles.button,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.farmerPrimaryLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Icon(icon, color: AppColors.farmerPrimary, size: 20),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              Text(subtitle, style: AppTextStyles.cardCaption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body2Secondary.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.body1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.iconDefault, size: 20)
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: maxLines > 1
                  ? AppDimensions.paddingL
                  : AppDimensions.paddingM,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              borderSide: const BorderSide(
                color: AppColors.farmerPrimary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection() {
    final certifications = _userProfile?.businessInfo?.certifications ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.workspace_premium_outlined,
          title: 'Certifications',
          subtitle: 'Display your farm certifications',
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildCard(
          children: [
            if (certifications.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingXL,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      Text(
                        'No certifications added yet',
                        style: AppTextStyles.body2Secondary,
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        'Add certifications like Organic, Fair Trade, etc.',
                        style: AppTextStyles.cardCaption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...certifications.map((cert) => _buildCertificationTile(cert)),
            const SizedBox(height: AppDimensions.spacingM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddCertificationDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Certification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.farmerPrimary,
                  side: const BorderSide(color: AppColors.farmerPrimary),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCertificationTile(Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: cert.isValid ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            _getCertificationIcon(cert.type),
            color: cert.isValid ? AppColors.success : AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.name, style: AppTextStyles.labelMedium),
                if (cert.expiryDate != null)
                  Text(
                    cert.isValid
                        ? 'Expires: ${_formatDate(cert.expiryDate!)}'
                        : 'Expired: ${_formatDate(cert.expiryDate!)}',
                    style: AppTextStyles.cardCaption.copyWith(
                      color: cert.isValid
                          ? AppColors.textSecondary
                          : AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => _removeCertification(cert),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showAddCertificationDialog() {
    final nameController = TextEditingController();
    CertificationType selectedType = CertificationType.organic;
    DateTime? expiryDate;

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
              const SizedBox(height: AppDimensions.spacingL),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expiryDate != null
                          ? 'Expires: ${_formatDate(expiryDate!)}'
                          : 'No expiry date',
                      style: AppTextStyles.body2Secondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) {
                        setDialogState(() => expiryDate = date);
                      }
                    },
                    child: Text(expiryDate != null ? 'Change' : 'Set Date'),
                  ),
                ],
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
                  _addCertification(
                    Certification(
                      name: nameController.text.trim(),
                      type: selectedType,
                      expiryDate: expiryDate,
                    ),
                  );
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

  void _addCertification(Certification certification) {
    if (_userProfile == null) return;

    final currentCerts = _userProfile!.businessInfo?.certifications ?? [];
    final updatedBusinessInfo =
        (_userProfile!.businessInfo ??
                BusinessInfo(farmName: _farmNameController.text.trim()))
            .copyWith(certifications: [...currentCerts, certification]);

    setState(() {
      _userProfile = _userProfile!.copyWith(businessInfo: updatedBusinessInfo);
    });
  }

  void _removeCertification(Certification certification) {
    if (_userProfile == null) return;

    final currentCerts = _userProfile!.businessInfo?.certifications ?? [];
    final updatedCerts = currentCerts.where((c) => c != certification).toList();
    final updatedBusinessInfo = _userProfile!.businessInfo?.copyWith(
      certifications: updatedCerts,
    );

    setState(() {
      _userProfile = _userProfile!.copyWith(businessInfo: updatedBusinessInfo);
    });
  }

  Widget _buildPickupLocationsSection() {
    final locations = _userProfile?.businessInfo?.pickupLocations ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.location_on_outlined,
          title: 'Pickup Locations',
          subtitle: 'Manage where customers can pick up orders',
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildCard(
          children: [
            if (locations.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingXL,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      Text(
                        'No pickup locations added yet',
                        style: AppTextStyles.body2Secondary,
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        'Add locations where customers can collect their orders',
                        style: AppTextStyles.cardCaption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...locations.map((loc) => _buildPickupLocationTile(loc)),
            const SizedBox(height: AppDimensions.spacingM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showPickupLocationDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.farmerPrimary,
                  side: const BorderSide(color: AppColors.farmerPrimary),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickupLocationTile(PickupLocation location) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.farmerPrimaryLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.farmerPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.address,
                      style: AppTextStyles.body2Secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              _buildIconButton(
                icon: Icons.edit_outlined,
                color: AppColors.textSecondary,
                onPressed: () => _showPickupLocationDialog(location: location),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              _buildIconButton(
                icon: Icons.delete_outline,
                color: AppColors.error,
                onPressed: () => _removePickupLocation(location),
              ),
            ],
          ),
          if (location.notes.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      location.notes,
                      style: AppTextStyles.caption.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (location.availableWindows.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.spacingM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _groupWindows(location.availableWindows).map((text) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.farmerPrimaryLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.farmerPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        text,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.farmerPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  List<String> _groupWindows(List<PickupWindow> windows) {
    if (windows.isEmpty) return [];

    // Sort by dayOfWeek
    final sortedWindows = List<PickupWindow>.from(windows)
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    final results = <String>[];
    if (sortedWindows.isEmpty) return results;

    var startDay = sortedWindows[0].dayOfWeek;
    var lastDay = startDay;
    var currentTimeRange = sortedWindows[0].formattedTimeRange;

    for (var i = 1; i < sortedWindows.length; i++) {
      final w = sortedWindows[i];
      if (w.dayOfWeek == lastDay + 1 &&
          w.formattedTimeRange == currentTimeRange) {
        lastDay = w.dayOfWeek;
      } else {
        results.add('${_formatDayRange(startDay, lastDay)}: $currentTimeRange');
        startDay = w.dayOfWeek;
        lastDay = startDay;
        currentTimeRange = w.formattedTimeRange;
      }
    }
    results.add('${_formatDayRange(startDay, lastDay)}: $currentTimeRange');

    return results;
  }

  String _formatDayRange(int start, int end) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (start == end) return days[start - 1];
    if (end == start + 1) return '${days[start - 1]}, ${days[end - 1]}';
    return '${days[start - 1]} - ${days[end - 1]}';
  }

  void _showPickupLocationDialog({PickupLocation? location}) {
    final nameController = TextEditingController(text: location?.name ?? '');
    final addressController = TextEditingController(
      text: location?.address ?? '',
    );
    final notesController = TextEditingController(text: location?.notes ?? '');
    List<PickupWindow> windows = List.from(location?.availableWindows ?? []);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            titlePadding: const EdgeInsets.all(AppDimensions.paddingL),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
            ),
            actionsPadding: const EdgeInsets.all(AppDimensions.paddingL),
            title: Row(
              children: [
                Icon(
                  location == null ? Icons.add_location : Icons.edit_location,
                  color: AppColors.farmerPrimary,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Text(
                  location == null ? 'Add Location' : 'Edit Location',
                  style: AppTextStyles.h4,
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'Location Name',
                      hint: 'e.g., Farm Stand, Downtown Market',
                    ),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildDialogTextField(
                      controller: addressController,
                      label: 'Address',
                      hint: 'Street, City, Postcode',
                    ),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildDialogTextField(
                      controller: notesController,
                      label: 'Pickup Instructions (Optional)',
                      hint: 'e.g., Park behind the main barn',
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pickup Windows', style: AppTextStyles.labelLarge),
                        TextButton.icon(
                          onPressed: () async {
                            final window = await _showAddWindowDialog(context);
                            if (window != null) {
                              setDialogState(() {
                                windows.add(window);
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Time'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.farmerPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    if (windows.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingL,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 32,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingS),
                              Text(
                                'No pickup times added yet',
                                style: AppTextStyles.body2Secondary,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...windows.asMap().entries.map((entry) {
                        final w = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppDimensions.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.today,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            title: Text(
                              w.dayName,
                              style: AppTextStyles.labelMedium,
                            ),
                            subtitle: Text(w.formattedTimeRange),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColors.error,
                              onPressed: () {
                                setDialogState(() {
                                  windows.removeAt(entry.key);
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: AppDimensions.spacingM),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty &&
                      addressController.text.trim().isNotEmpty) {
                    final newLocation = PickupLocation(
                      id:
                          location?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      notes: notesController.text.trim(),
                      availableWindows: windows,
                    );
                    _savePickupLocation(newLocation);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.farmerPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                ),
                child: const Text('Save Location'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.body2,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body2Secondary.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingM,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.farmerPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Future<PickupWindow?> _showAddWindowDialog(BuildContext context) async {
    int dayOfWeek = 1; // Monday
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    return showDialog<PickupWindow>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            title: Text('Add Time Slot', style: AppTextStyles.h4),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Day', style: AppTextStyles.labelSmall),
                const SizedBox(height: AppDimensions.spacingS),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = dayOfWeek == day;
                    final dayNames = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    return ChoiceChip(
                      label: Text(
                        dayNames[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => dayOfWeek = day);
                        }
                      },
                      selectedColor: AppColors.farmerPrimary,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.border,
                      ),
                      showCheckmark: false,
                    );
                  }),
                ),
                const SizedBox(height: AppDimensions.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (t != null) {
                                setDialogState(() => startTime = t);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    startTime.format(context),
                                    style: AppTextStyles.body2,
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (t != null) {
                                setDialogState(() => endTime = t);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    endTime.format(context),
                                    style: AppTextStyles.body2,
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    PickupWindow(
                      dayOfWeek: dayOfWeek,
                      startHour: startTime.hour,
                      startMinute: startTime.minute,
                      endHour: endTime.hour,
                      endMinute: endTime.minute,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.farmerPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: const Text('Add Slot'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _savePickupLocation(PickupLocation location) {
    if (_userProfile == null) return;
    final currentLocations = List<PickupLocation>.from(
      _userProfile!.businessInfo?.pickupLocations ?? [],
    );
    final index = currentLocations.indexWhere((l) => l.id == location.id);
    if (index >= 0) {
      currentLocations[index] = location;
    } else {
      currentLocations.add(location);
    }
    final updatedBusinessInfo =
        _userProfile!.businessInfo?.copyWith(
          pickupLocations: currentLocations,
        ) ??
        BusinessInfo(
          farmName: _farmNameController.text,
          pickupLocations: currentLocations,
        );
    setState(() {
      _userProfile = _userProfile!.copyWith(businessInfo: updatedBusinessInfo);
    });
  }

  void _removePickupLocation(PickupLocation location) {
    if (_userProfile == null) return;
    final currentLocations = List<PickupLocation>.from(
      _userProfile!.businessInfo?.pickupLocations ?? [],
    );
    currentLocations.removeWhere((l) => l.id == location.id);
    final updatedBusinessInfo =
        _userProfile!.businessInfo?.copyWith(
          pickupLocations: currentLocations,
        ) ??
        BusinessInfo(
          farmName: _farmNameController.text,
          pickupLocations: currentLocations,
        );
    setState(() {
      _userProfile = _userProfile!.copyWith(businessInfo: updatedBusinessInfo);
    });
  }
}

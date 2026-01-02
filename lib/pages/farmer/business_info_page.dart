import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/user_profile.dart';
import 'package:farmdashr/data/repositories/user_repository.dart';

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
    _farmNameController.dispose();
    _descriptionController.dispose();
    _licenseController.dispose();
    _hoursController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userProfile == null) return;

    setState(() => _isSaving = true);
    try {
      final updatedBusinessInfo = BusinessInfo(
        farmName: _farmNameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        businessLicense: _licenseController.text.trim().isNotEmpty
            ? _licenseController.text.trim()
            : null,
        certifications: _userProfile!.businessInfo?.certifications ?? [],
        operatingHours: _hoursController.text.trim().isNotEmpty
            ? _hoursController.text.trim()
            : null,
        facebookUrl: _facebookController.text.trim().isNotEmpty
            ? _facebookController.text.trim()
            : null,
        instagramUrl: _instagramController.text.trim().isNotEmpty
            ? _instagramController.text.trim()
            : null,
      );

      final updatedProfile = _userProfile!.copyWith(
        businessInfo: updatedBusinessInfo,
      );

      await _userRepo.update(updatedProfile);

      if (mounted) {
        setState(() {
          _userProfile = updatedProfile;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business information saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Business Information',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Form(
                    key: _formKey,
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
                                  value == null || value.isEmpty
                                  ? 'Farm name is required'
                                  : null,
                            ),
                            const SizedBox(height: AppDimensions.spacingL),
                            _buildTextField(
                              label: 'Description',
                              hint:
                                  'Tell customers about your farm, your story, and what makes you unique...',
                              controller: _descriptionController,
                              maxLines: 4,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXL),
                        _buildSectionHeader(
                          icon: Icons.verified_outlined,
                          title: 'Business License',
                          subtitle: 'Your official business credentials',
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        _buildCard(
                          children: [
                            _buildTextField(
                              label: 'License Number',
                              hint: 'e.g. BUS-2024-12345',
                              controller: _licenseController,
                              prefixIcon: Icons.badge_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXL),
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
                        const SizedBox(
                          height: 100,
                        ), // Space for floating button
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppDimensions.paddingL,
                  right: AppDimensions.paddingL,
                  bottom: AppDimensions.paddingL,
                  child: _buildSaveButton(),
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.7),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
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

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.farmerPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveBusinessInfo,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.farmerPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_outlined, size: 20),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              'Save Changes',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

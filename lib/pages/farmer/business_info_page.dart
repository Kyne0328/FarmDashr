import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';

import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/presentation/widgets/common/farm_dropdown.dart';
import 'package:farmdashr/presentation/widgets/common/pickup_location_tile.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';

class BusinessInfoPage extends StatefulWidget {
  const BusinessInfoPage({super.key});

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepo = FirestoreUserRepository();

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
        operatingHours: _formatOperatingHours().isNotEmpty
            ? _formatOperatingHours()
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

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _licenseController = TextEditingController();
    // _hoursController removed
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _loadUserProfile();
  }

  // Operating Hours State
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  final Set<int> _operatingDays = {};

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

  Widget _buildOperatingHoursSection() {
    return Column(
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
            Text(
              'Select the days and times you\'re available',
              style: AppTextStyles.body2Secondary,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _operatingDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    // HapticService.selection(); // Assuming global service
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
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
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
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
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
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            const Icon(
              Icons.access_time,
              color: AppColors.textSecondary,
              size: 20,
            ),
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

  @override
  void dispose() {
    _farmNameController.dispose();
    _descriptionController.dispose();
    _licenseController.dispose();
    // _hoursController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
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
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '* Fields are required',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          _buildDetailsSection(),
                          const SizedBox(height: AppDimensions.spacingXL),
                          _buildOperationsSection(),
                          const SizedBox(height: AppDimensions.spacingXL),
                          _buildSocialCertsSection(),
                          const SizedBox(
                            height: AppDimensions.spacingXL,
                          ), // Extra padding at bottom
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
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
            FarmTextField(
              label: 'Farm Name *',
              hint: 'e.g. Green Valley Farm',
              controller: _farmNameController,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            FarmTextField(
              label: 'Description',
              hint: 'Tell customers about your farm story...',
              controller: _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            FarmTextField(
              label: 'Business License',
              hint: 'e.g. BUS-2024-12345',
              controller: _licenseController,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOperatingHoursSection(),
        const SizedBox(height: AppDimensions.spacingXL),
        _buildPickupLocationsSection(),
      ],
    );
  }

  Widget _buildSocialCertsSection() {
    return Column(
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
            FarmTextField(
              label: 'Facebook',
              hint: 'https://facebook.com/yourfarm',
              controller: _facebookController,
              prefixIcon: const Icon(Icons.facebook),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            FarmTextField(
              label: 'Instagram',
              hint: 'https://instagram.com/yourfarm',
              controller: _instagramController,
              prefixIcon: const Icon(Icons.camera_alt_outlined),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXL),
        _buildCertificationsSection(),
      ],
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
        child: FarmButton(
          label: 'Save Information',
          onPressed: _isSaving ? null : _saveBusinessInfo,
          style: FarmButtonStyle.primary,
          backgroundColor: AppColors.farmerPrimary,
          isLoading: _isSaving,
          height: 56,
          isFullWidth: true,
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
              child: FarmButton(
                label: 'Add Certification',
                onPressed: _showAddCertificationDialog,
                icon: Icons.add,
                style: FarmButtonStyle.outline,
                textColor: AppColors.farmerPrimary,
                borderColor: AppColors.farmerPrimary,
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
      case CertificationType.philGap:
        return Icons.shield_moon; // Shield for GAP
      case CertificationType.halal:
        return Icons.restaurant; // Halal symbol placeholder
      case CertificationType.other:
        return Icons.verified;
    }
  }

  String _getCertificationTypeLabel(CertificationType type) {
    switch (type) {
      case CertificationType.organic:
        return 'Organic (PNS-OA)';
      case CertificationType.philGap:
        return 'PhilGAP';
      case CertificationType.halal:
        return 'Halal';
      case CertificationType.other:
        return 'Other';
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
              FarmTextField(
                controller: nameController,
                label: 'Certification Name',
                hint: 'e.g. USDA Organic',
              ),
              const SizedBox(height: AppDimensions.spacingL),
              FarmDropdown<CertificationType>(
                label: 'Type',
                value: selectedType,
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
                  SizedBox(
                    width: 100,
                    child: FarmButton(
                      label: expiryDate != null ? 'Change' : 'Set Date',
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
                      style: FarmButtonStyle.ghost,
                      height: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: 100,
              child: FarmButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
                style: FarmButtonStyle.ghost,
                textColor: AppColors.textSecondary,
                height: 48,
              ),
            ),
            SizedBox(
              width: 100,
              child: FarmButton(
                label: 'Add',
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
                style: FarmButtonStyle.primary,
                backgroundColor: AppColors.farmerPrimary,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
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
              ...locations.map(
                (loc) => PickupLocationTile(
                  location: loc,
                  onEdit: () => _showPickupLocationDialog(location: loc),
                  onDelete: () => _removePickupLocation(loc),
                ),
              ),
            const SizedBox(height: AppDimensions.spacingM),
            SizedBox(
              width: double.infinity,
              child: FarmButton(
                label: 'Add Location',
                onPressed: () => _showPickupLocationDialog(),
                icon: Icons.add,
                style: FarmButtonStyle.outline,
                textColor: AppColors.farmerPrimary,
                borderColor: AppColors.farmerPrimary,
              ),
            ),
          ],
        ),
      ],
    );
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
                    FarmTextField(
                      controller: nameController,
                      label: 'Location Name',
                      hint: 'e.g., Farm Stand, Downtown Market',
                    ),
                    const SizedBox(height: AppDimensions.spacingL),
                    FarmTextField(
                      controller: addressController,
                      label: 'Address',
                      hint: 'Street, City, Postcode',
                    ),
                    const SizedBox(height: AppDimensions.spacingL),
                    FarmTextField(
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
                        FarmButton(
                          onPressed: () async {
                            final newWindows = await _showAddWindowDialog(
                              context,
                              windows,
                            );
                            if (newWindows != null && newWindows.isNotEmpty) {
                              setDialogState(() {
                                windows.addAll(newWindows);
                              });
                            }
                          },
                          icon: Icons.add,
                          label: 'Add Time',
                          style: FarmButtonStyle.ghost,
                          textColor: AppColors.farmerPrimary,
                          height: 36,
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
              SizedBox(
                width: 100,
                child: FarmButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  style: FarmButtonStyle.ghost,
                  textColor: AppColors.textSecondary,
                  height: 48,
                ),
              ),
              SizedBox(
                width: 140,
                child: FarmButton(
                  label: 'Save Location',
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
                  style: FarmButtonStyle.primary,
                  backgroundColor: AppColors.farmerPrimary,
                  height: 48,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<PickupWindow>?> _showAddWindowDialog(
    BuildContext context,
    List<PickupWindow> existingWindows,
  ) async {
    Set<int> selectedDays = {}; // Multiple days
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    return showDialog<List<PickupWindow>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Check for conflicts
          String? conflictMessage;
          if (selectedDays.isNotEmpty) {
            for (final day in selectedDays) {
              for (final existing in existingWindows) {
                if (existing.dayOfWeek == day) {
                  // Check time overlap
                  final existingStart =
                      existing.startHour * 60 + existing.startMinute;
                  final existingEnd =
                      existing.endHour * 60 + existing.endMinute;
                  final newStart = startTime.hour * 60 + startTime.minute;
                  final newEnd = endTime.hour * 60 + endTime.minute;

                  if ((newStart < existingEnd && newEnd > existingStart)) {
                    conflictMessage =
                        'Conflicts with existing ${existing.dayName} slot';
                    break;
                  }
                }
              }
              if (conflictMessage != null) break;
            }
          }

          // Check if end time is after start time
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;
          if (endMinutes <= startMinutes) {
            conflictMessage = 'End time must be after start time';
          }

          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            title: Text('Add Time Slot', style: AppTextStyles.h4),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Days', style: AppTextStyles.labelSmall),
                const SizedBox(height: AppDimensions.spacingS),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = selectedDays.contains(day);
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
                        setDialogState(() {
                          if (selected) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                        });
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
                if (conflictMessage != null) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusS,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            conflictMessage,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              SizedBox(
                width: 100,
                child: FarmButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  style: FarmButtonStyle.ghost,
                  textColor: AppColors.textSecondary,
                  height: 48,
                ),
              ),
              SizedBox(
                width: 100,
                child: FarmButton(
                  label: 'Add Slots',
                  onPressed: selectedDays.isEmpty || conflictMessage != null
                      ? null
                      : () {
                          final windows = selectedDays.map((day) {
                            return PickupWindow(
                              dayOfWeek: day,
                              startHour: startTime.hour,
                              startMinute: startTime.minute,
                              endHour: endTime.hour,
                              endMinute: endTime.minute,
                            );
                          }).toList();
                          Navigator.pop(context, windows);
                        },
                  style: FarmButtonStyle.primary,
                  backgroundColor: AppColors.farmerPrimary,
                  height: 48,
                ),
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

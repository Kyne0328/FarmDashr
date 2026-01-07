import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/blocs/cart/cart.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/order/order.dart';

import 'package:farmdashr/presentation/widgets/common/step_indicator.dart';
import 'package:farmdashr/presentation/widgets/common/map_display_widget.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/data/services/location_service.dart';

class PreOrderCheckoutPage extends StatefulWidget {
  /// Optional items for "Buy Now" mode - bypasses cart entirely
  final List<CartItem>? buyNowItems;

  const PreOrderCheckoutPage({super.key, this.buyNowItems});

  @override
  State<PreOrderCheckoutPage> createState() => _PreOrderCheckoutPageState();
}

class _PreOrderCheckoutPageState extends State<PreOrderCheckoutPage> {
  final UserRepository _userRepo = FirestoreUserRepository();

  // Controllers for each farmer in the cart
  final Map<String, _PickupFormController> _farmerControllers = {};

  // Cache for farmer profiles
  final Map<String, UserProfile> _farmerProfiles = {};

  bool _isLoadingProfiles = true;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<String> _stepLabels = ['Pickup', 'Review', 'Confirm'];

  @override
  void initState() {
    super.initState();
    _loadFarmerProfiles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _farmerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Get items - either buyNowItems or from cart
  List<CartItem> get _items {
    if (widget.buyNowItems != null && widget.buyNowItems!.isNotEmpty) {
      return widget.buyNowItems!;
    }
    final state = context.read<CartBloc>().state;
    if (state is CartLoaded) {
      return state.items;
    }
    return [];
  }

  /// Check if this is a "Buy Now" checkout (not from cart)
  bool get _isBuyNowMode =>
      widget.buyNowItems != null && widget.buyNowItems!.isNotEmpty;

  Future<void> _loadFarmerProfiles() async {
    final items = _items;
    if (items.isNotEmpty) {
      final farmerIds = items.map((e) => e.product.farmerId).toSet();

      for (final id in farmerIds) {
        if (!_farmerProfiles.containsKey(id)) {
          try {
            final profile = await _userRepo.getById(id);
            if (profile != null) {
              _farmerProfiles[id] = profile;
              // Initialize controller
              final farmerName = profile.businessInfo?.farmName ?? profile.name;
              _farmerControllers[id] = _PickupFormController(id, farmerName);
            }
          } catch (_) {
            // Error loading profile - skip
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingProfiles = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0) {
        // Validate pickup details
        for (var controller in _farmerControllers.values) {
          if (controller.selectedLocation == null ||
              controller.selectedDate == null ||
              controller.selectedTime == null) {
            SnackbarHelper.showError(
              context,
              'Please select pickup details for ${controller.farmerName}',
            );
            return;
          }
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _onConfirmCheckout();
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
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
          context.go('/customer-orders');
        } else if (state is CartCheckoutPartialSuccess) {
          // Partial success - some orders placed, some failed
          SnackbarHelper.showInfo(
            context,
            state.message,
            duration: const Duration(seconds: 5),
          );
          context.go('/customer-orders');
        } else if (state is CartError) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              HapticService.selection();
              _previousStep();
            },
          ),
          title: const Text('Checkout'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Builder(
          builder: (context) {
            // For Buy Now mode, we don't need to check cart state
            // For cart mode, we still need to verify cart is loaded
            if (!_isBuyNowMode) {
              final cartState = context.watch<CartBloc>().state;
              if (cartState is! CartLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
            }

            if (_isLoadingProfiles) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = _items;
            final itemsByFarmer = _groupItemsByFarmer(items);
            final double total = items.fold(
              0.0,
              (sum, item) => sum + item.total,
            );

            // Filter pickup locations for each farmer based on product constraints
            final Map<String, List<PickupLocation>> filteredFarmerLocations =
                {};
            for (final farmerId in itemsByFarmer.keys) {
              final items = itemsByFarmer[farmerId]!;
              final profile = _farmerProfiles[farmerId];
              if (profile == null) continue;

              final allPickupLocations =
                  profile.businessInfo?.pickupLocations ?? [];

              Set<String>? commonLocationIds;
              bool hasProductConstraints = false;

              for (final item in items) {
                final productLocs = item.product.pickupLocationIds;
                if (productLocs.isNotEmpty) {
                  hasProductConstraints = true;
                  if (commonLocationIds == null) {
                    commonLocationIds = productLocs.toSet();
                  } else {
                    commonLocationIds = commonLocationIds.intersection(
                      productLocs.toSet(),
                    );
                  }
                }
              }

              if (!hasProductConstraints) {
                filteredFarmerLocations[farmerId] = allPickupLocations;
              } else if (commonLocationIds == null ||
                  commonLocationIds.isEmpty) {
                filteredFarmerLocations[farmerId] = [];
              } else {
                filteredFarmerLocations[farmerId] = allPickupLocations
                    .where((loc) => commonLocationIds!.contains(loc.id))
                    .toList();
              }
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                  ),
                  child: StepIndicator(
                    currentStep: _currentStep,
                    totalSteps: 3,
                    stepLabels: _stepLabels,
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPickupStep(itemsByFarmer, filteredFarmerLocations),
                      _buildReviewStep(itemsByFarmer),
                      _buildConfirmStep(items, total),
                    ],
                  ),
                ),
                _buildBottomAction(total),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPickupStep(
    Map<String, List<CartItem>> itemsByFarmer,
    Map<String, List<PickupLocation>> filteredFarmerLocations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Pickup Details', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'Select where and when you will pick up your produce from each farmer.',
            style: AppTextStyles.body2Secondary,
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          ...itemsByFarmer.entries.map((entry) {
            final farmerId = entry.key;
            return _buildFarmerPickupSection(
              farmerId,
              filteredFarmerLocations[farmerId] ?? [],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewStep(Map<String, List<CartItem>> itemsByFarmer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Order', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'Review your items and add any special instructions for the farmer.',
            style: AppTextStyles.body2Secondary,
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          ...itemsByFarmer.entries.map((entry) {
            final farmerId = entry.key;
            final items = entry.value;
            return _buildFarmerReviewSection(farmerId, items);
          }),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(List<CartItem> items, double total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacingXL),
          const Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          Text('Ready to Place Order?', style: AppTextStyles.h2),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'Your order will be sent to the farmers. You will receive a notification once they confirm.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body2Secondary,
          ),
          const SizedBox(height: AppDimensions.spacingXXL),
          _buildOrderSummary(items, total),
          const SizedBox(height: AppDimensions.spacingXL),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Text(
                    'No payment is required now. You will pay upon pickup.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(double total) {
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
              FarmButton(
                label: 'Back',
                onPressed: _previousStep,
                style: FarmButtonStyle.outline,
                width: 100,
                height: 56,
              ),
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: FarmButton(
                label: _currentStep == 2 ? 'Place Order' : 'Continue',
                onPressed: () {
                  HapticService.heavy();
                  _nextStep();
                },
                style: FarmButtonStyle.primary,
                height: 56,
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerPickupSection(
    String farmerId,
    List<PickupLocation> pickupLocations,
  ) {
    final controller = _farmerControllers[farmerId];
    if (controller == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: AppColors.farmerPrimary),
              const SizedBox(width: 8),
              Text(controller.farmerName, style: AppTextStyles.labelLarge),
            ],
          ),
          const Divider(height: 24),
          if (pickupLocations.isEmpty)
            _buildNoLocationsError()
          else
            _buildPickupSelection(controller, pickupLocations),
        ],
      ),
    );
  }

  Widget _buildFarmerReviewSection(String farmerId, List<CartItem> items) {
    final controller = _farmerControllers[farmerId];
    if (controller == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(controller.farmerName, style: AppTextStyles.labelLarge),
          const Divider(height: 24),
          ...items.map((item) => _buildReviewItem(item)),
          const SizedBox(height: 16),
          _buildPickupSummary(controller),
          const SizedBox(height: 16),
          _buildSpecialInstructions(controller),
        ],
      ),
    );
  }

  Widget _buildReviewItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.product.name} x ${item.quantity}',
              style: AppTextStyles.body2,
            ),
          ),
          Text(
            '₱${item.total.toStringAsFixed(2)}',
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSummary(_PickupFormController controller) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${controller.selectedLocation?.name}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${controller.selectedDate?.day}/${controller.selectedDate?.month}/${controller.selectedDate?.year} at ${controller.selectedTime?.format(context)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(_PickupFormController controller) {
    return FarmTextField(
      controller: controller.instructionsController,
      label: 'Notes (Optional)',
      hint: 'Any special requests...',
      maxLines: 2,
    );
  }

  Widget _buildNoLocationsError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'No common pickup locations found for these items.',
        style: TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _buildPickupSelection(
    _PickupFormController controller,
    List<PickupLocation> pickupLocations,
  ) {
    // Prepare map markers
    final locationsWithCoords = pickupLocations
        .where((loc) => loc.coordinates != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locationsWithCoords.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: MapDisplayWidget(
              markers: locationsWithCoords
                  .map(
                    (loc) => MapMarkerData(
                      id: loc.id,
                      location: loc.coordinates!,
                      title: loc.name,
                      subtitle: loc.address,
                    ),
                  )
                  .toList(),
              height: 200,
              showSelectedMarkerInfo: false,
              selectedMarkerId: controller.selectedLocation?.id,
              onMarkerTap: (marker) {
                final selectedLoc = pickupLocations.firstWhere(
                  (l) => l.id == marker.id,
                );
                setState(() {
                  controller.selectedLocation = selectedLoc;
                  controller.selectedDate = null;
                  controller.selectedTime = null;
                });
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        const Text('Select a location:', style: AppTextStyles.body2Secondary),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: pickupLocations.map((loc) {
              final isSelected = controller.selectedLocation?.id == loc.id;
              return _buildLocationCard(loc, isSelected, (selectedLoc) {
                setState(() {
                  controller.selectedLocation = selectedLoc;
                  controller.selectedDate = null;
                  controller.selectedTime = null;
                });
              });
            }).toList(),
          ),
        ),
        if (controller.selectedLocation != null) ...[
          const SizedBox(height: AppDimensions.spacingL),
          _buildDateTimePickers(controller),
        ],
      ],
    );
  }

  Widget _buildDateTimePickers(_PickupFormController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildPickerButton(
            label: 'Pickup Date',
            value: controller.selectedDate != null
                ? '${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}'
                : 'Select Date',
            icon: Icons.calendar_today,
            onTap: () => _selectDate(controller),
            isSelected: controller.selectedDate != null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPickerButton(
            label: 'Pickup Time',
            value: controller.selectedTime != null
                ? controller.selectedTime!.format(context)
                : 'Select Time',
            icon: Icons.access_time,
            onTap: () => _selectTime(controller),
            isSelected: controller.selectedTime != null,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  value,
                  style: isSelected
                      ? AppTextStyles.body2
                      : AppTextStyles.body2Secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<CartItem>> _groupItemsByFarmer(List<CartItem> items) {
    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.product.farmerId)) {
        grouped[item.product.farmerId] = [];
      }
      grouped[item.product.farmerId]!.add(item);
    }
    return grouped;
  }

  Widget _buildLocationCard(
    PickupLocation loc,
    bool isSelected,
    Function(PickupLocation) onSelect,
  ) {
    return GestureDetector(
      onTap: () => onSelect(loc),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.02),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              loc.address,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'Available Windows:',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ..._groupWindows(loc.availableWindows).map((text) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 10,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Get Directions button if coordinates available
            if (loc.coordinates != null) ...[
              const SizedBox(height: AppDimensions.spacingM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    LocationService().openDirections(loc.coordinates!);
                  },
                  icon: const Icon(Icons.directions, size: 14),
                  label: const Text('Get Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _groupWindows(List<PickupWindow> windows) {
    if (windows.isEmpty) return [];

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

  Future<void> _selectDate(_PickupFormController controller) async {
    final location = controller.selectedLocation;
    if (location == null) return;

    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 30)),
      selectableDayPredicate: (date) {
        return location.availableWindows.any(
          (w) => w.dayOfWeek == date.weekday,
        );
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.selectedDate = picked;
        controller.selectedTime = null;
      });
    }
  }

  Future<void> _selectTime(_PickupFormController controller) async {
    final location = controller.selectedLocation;
    final date = controller.selectedDate;

    if (location == null || date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location and date first.'),
        ),
      );
      return;
    }

    final windows = location.availableWindows
        .where((w) => w.dayOfWeek == date.weekday)
        .toList();
    if (windows.isEmpty) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      bool isValid = false;
      for (final w in windows) {
        final startMinutes = w.startHour * 60 + w.startMinute;
        final endMinutes = w.endHour * 60 + w.endMinute;
        final pickedMinutes = picked.hour * 60 + picked.minute;

        if (pickedMinutes >= startMinutes && pickedMinutes <= endMinutes) {
          isValid = true;
          break;
        }
      }

      if (isValid) {
        setState(() {
          controller.selectedTime = picked;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select a time between available hours: ${windows.map((w) => w.formattedTimeRange).join(", ")}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildOrderSummary(List<CartItem> items, double total) {
    final formattedTotal = '₱${total.toStringAsFixed(2)}';
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Amount', style: AppTextStyles.h4),
          Text(
            formattedTotal,
            style: AppTextStyles.h4.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  void _onConfirmCheckout() async {
    final authState = context.read<AuthBloc>().state;
    if (!authState.isAuthenticated || authState.userId == null) {
      context.push('/login');
      return;
    }

    for (var entry in _farmerControllers.entries) {
      final controller = entry.value;
      if (!controller.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please complete pickup details for ${controller.farmerName}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final Map<String, OrderPickupDetails> pickupDetails = {};
    for (var entry in _farmerControllers.entries) {
      final id = entry.key;
      final controller = entry.value;

      pickupDetails[id] = OrderPickupDetails(
        pickupLocation:
            '${controller.selectedLocation!.name} (${controller.selectedLocation!.address})',
        pickupLocationCoordinates: controller.selectedLocation!.coordinates,
        pickupDate:
            '${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}',
        pickupTime: controller.selectedTime!.format(context),
        specialInstructions: controller.instructionsController.text,
      );
    }

    // For Buy Now mode, we create orders directly without affecting the cart
    if (_isBuyNowMode) {
      await _processBuyNowCheckout(
        customerId: authState.userId!,
        customerName: authState.displayName ?? 'Customer',
        pickupDetails: pickupDetails,
      );
    } else {
      // For cart mode, use the existing CheckoutCart event
      context.read<CartBloc>().add(
        CheckoutCart(
          customerId: authState.userId!,
          customerName: authState.displayName ?? 'Customer',
          pickupDetails: pickupDetails,
        ),
      );
    }
  }

  /// Process checkout for Buy Now mode - creates orders directly without affecting cart
  Future<void> _processBuyNowCheckout({
    required String customerId,
    required String customerName,
    required Map<String, OrderPickupDetails> pickupDetails,
  }) async {
    final items = _items;
    if (items.isEmpty) {
      SnackbarHelper.showError(context, 'No items to checkout');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final productRepo = context.read<ProductRepository>();
      final orderRepo = context.read<OrderRepository>();
      final userRepo = context.read<UserRepository>();

      // Validate stock and get fresh product data
      final Map<String, Product> refreshedProducts = {};
      for (final item in items) {
        final product = await productRepo.getById(item.product.id);
        if (product == null) {
          throw Exception('Product ${item.product.name} no longer exists.');
        }
        if (product.currentStock < item.quantity) {
          throw Exception(
            'Insufficient stock for ${product.name}. Available: ${product.currentStock}',
          );
        }
        refreshedProducts[product.id] = product;
      }

      // Group items by farmerId
      final Map<String, List<CartItem>> itemsByFarmer = {};
      for (final item in items) {
        if (!itemsByFarmer.containsKey(item.product.farmerId)) {
          itemsByFarmer[item.product.farmerId] = [];
        }
        itemsByFarmer[item.product.farmerId]!.add(item);
      }

      // Create orders for each farmer
      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final farmerItems = entry.value;

        // Fetch farmer profile for name
        String farmerName;
        try {
          final farmerProfile = await userRepo.getById(farmerId);
          farmerName =
              farmerProfile?.businessInfo?.farmName ??
              farmerProfile?.name ??
              refreshedProducts[farmerItems.first.product.id]?.farmerName ??
              farmerItems.first.product.farmerName;
        } catch (_) {
          farmerName =
              refreshedProducts[farmerItems.first.product.id]?.farmerName ??
              farmerItems.first.product.farmerName;
        }

        double subtotal = 0;
        final List<OrderItem> orderItems = [];

        for (final item in farmerItems) {
          final currentProduct = refreshedProducts[item.product.id]!;
          final itemTotal = currentProduct.price * item.quantity;
          subtotal += itemTotal;
          orderItems.add(
            OrderItem(
              productId: currentProduct.id,
              productName: currentProduct.name,
              productImageUrl: currentProduct.imageUrls.isNotEmpty
                  ? currentProduct.imageUrls.first
                  : null,
              quantity: item.quantity,
              price: currentProduct.price,
            ),
          );
        }

        final details = pickupDetails[farmerId];
        if (details == null) {
          throw Exception('Missing pickup details for farmer $farmerName');
        }

        final order = Order(
          id: '',
          customerId: customerId,
          customerName: customerName,
          farmerId: farmerId,
          farmerName: farmerName,
          itemCount: farmerItems.fold(0, (sum, item) => sum + item.quantity),
          createdAt: DateTime.now(),
          status: OrderStatus.pending,
          amount: subtotal,
          items: orderItems,
          pickupLocation: details.pickupLocation,
          pickupLocationCoordinates: details.pickupLocationCoordinates,
          pickupDate: details.pickupDate,
          pickupTime: details.pickupTime,
          specialInstructions: details.specialInstructions,
        );

        await orderRepo.create(order);
      }

      // Dismiss loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Navigate to orders page
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Order placed successfully!');
        context.go('/customer-orders');
      }
    } catch (e) {
      // Dismiss loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    }
  }
}

class _PickupFormController {
  final String farmerId;
  final String farmerName;
  PickupLocation? selectedLocation;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController instructionsController = TextEditingController();

  _PickupFormController(this.farmerId, this.farmerName);

  bool get isValid =>
      selectedLocation != null && selectedDate != null && selectedTime != null;

  void dispose() {
    instructionsController.dispose();
  }
}

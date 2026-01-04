import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/blocs/cart/cart.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/auth/auth_state.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';

class PreOrderCheckoutPage extends StatefulWidget {
  const PreOrderCheckoutPage({super.key});

  @override
  State<PreOrderCheckoutPage> createState() => _PreOrderCheckoutPageState();
}

class _PreOrderCheckoutPageState extends State<PreOrderCheckoutPage> {
  final UserRepository _userRepo = UserRepository();

  // Controllers for each farmer in the cart
  final Map<String, _PickupFormController> _farmerControllers = {};

  // Cache for farmer profiles
  final Map<String, UserProfile> _farmerProfiles = {};

  bool _isLoadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerProfiles();
  }

  @override
  void dispose() {
    for (var controller in _farmerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFarmerProfiles() async {
    final state = context.read<CartBloc>().state;
    if (state is CartLoaded) {
      final farmerIds = state.items.map((e) => e.product.farmerId).toSet();

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
          } catch (e) {
            debugPrint('Error loading profile for $id: $e');
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/customer-orders');
        } else if (state is CartError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.info),
            onPressed: () => context.pop(),
          ),
          title: const Text('Pre-Order Checkout'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is! CartLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_isLoadingProfiles) {
              return const Center(child: CircularProgressIndicator());
            }

            final itemsByFarmer = _groupItemsByFarmer(state.items);
            final double total = state.totalPrice;

            // Filter pickup locations for each farmer based on product constraints
            final Map<String, List<PickupLocation>> filteredFarmerLocations =
                {};
            for (final farmerId in itemsByFarmer.keys) {
              final items = itemsByFarmer[farmerId]!;
              final profile = _farmerProfiles[farmerId];
              if (profile == null) continue;

              final allPickupLocations =
                  profile.businessInfo?.pickupLocations ?? [];

              // Find intersection of pickupLocationIds for all products from this farmer
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...itemsByFarmer.entries.map((entry) {
                    final farmerId = entry.key;
                    final items = entry.value;
                    return _buildFarmerSection(
                      farmerId,
                      items,
                      filteredFarmerLocations[farmerId] ?? [],
                    );
                  }),
                  const SizedBox(height: AppDimensions.spacingXL),
                  _buildOrderSummary(state, total),
                  const SizedBox(height: AppDimensions.spacingXL),
                  _buildConfirmButton(total),
                  const SizedBox(height: AppDimensions.spacingXL),
                ],
              ),
            );
          },
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

  Widget _buildFarmerSection(
    String farmerId,
    List<CartItem> items,
    List<PickupLocation> pickupLocations,
  ) {
    final profile = _farmerProfiles[farmerId];
    final controller = _farmerControllers[farmerId];

    if (profile == null || controller == null) {
      return const SizedBox.shrink();
    }

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
              Text(controller.farmerName, style: AppTextStyles.h4),
            ],
          ),
          const Divider(height: 24),
          // Items from this farmer
          ...items.map(
            (item) => Padding(
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
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Pickup Details', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),

          // Location Selection
          if (pickupLocations.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No common pickup locations found for these items.',
                style: TextStyle(color: AppColors.error),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a location:',
                  style: AppTextStyles.body2Secondary,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: pickupLocations.map((loc) {
                      final isSelected =
                          controller.selectedLocation?.id == loc.id;
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
              ],
            ),

          if (controller.selectedLocation != null) ...[
            const SizedBox(height: AppDimensions.spacingL),
            // Location Details (Special Instructions)
            if (controller.selectedLocation!.notes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.infoDark,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Instructions:',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.infoDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.selectedLocation!.notes,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(controller),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Date',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: AppDimensions.spacingS),
                              Text(
                                controller.selectedDate != null
                                    ? '${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}'
                                    : 'Select Date',
                                style: controller.selectedDate != null
                                    ? AppTextStyles.body2
                                    : AppTextStyles.body2Secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(controller),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Time',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: AppDimensions.spacingS),
                              Text(
                                controller.selectedTime != null
                                    ? controller.selectedTime!.format(context)
                                    : 'Select Time',
                                style: controller.selectedTime != null
                                    ? AppTextStyles.body2
                                    : AppTextStyles.body2Secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: controller.instructionsController,
            decoration: InputDecoration(
              labelText: 'Order Notes for Farmer (Optional)',
              hintText: 'e.g., Please leave at the gate if I am late...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLines: 2,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
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
              ? AppColors.info.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.info : AppColors.border,
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
                        ? AppColors.info.withValues(alpha: 0.1)
                        : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: isSelected
                        ? AppColors.info
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
                          ? AppColors.infoDark
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
                    color: AppColors.info,
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
                      color: AppColors.info,
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
              primary: AppColors.info,
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
              primary: AppColors.info,
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

  Widget _buildOrderSummary(CartLoaded state, double total) {
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
            state.formattedTotal,
            style: AppTextStyles.h4.copyWith(color: AppColors.info),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(double total) {
    return ElevatedButton(
      onPressed: _onConfirmCheckout,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: const Text('Confirm Pre-Order'),
    );
  }

  void _onConfirmCheckout() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
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
        pickupDate:
            '${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}',
        pickupTime: controller.selectedTime!.format(context),
        specialInstructions: controller.instructionsController.text,
      );
    }

    context.read<CartBloc>().add(
      CheckoutCart(
        customerId: authState.userId!,
        customerName: authState.displayName ?? 'Customer',
        pickupDetails: pickupDetails,
      ),
    );
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

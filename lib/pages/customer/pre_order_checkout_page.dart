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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...itemsByFarmer.entries.map((entry) {
                    final farmerId = entry.key;
                    final items = entry.value;
                    return _buildFarmerSection(farmerId, items);
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

  Widget _buildFarmerSection(String farmerId, List<CartItem> items) {
    final profile = _farmerProfiles[farmerId];
    final controller = _farmerControllers[farmerId];

    if (profile == null || controller == null) {
      return const SizedBox.shrink(); // Should handle error better
    }

    final pickupLocations = profile.businessInfo?.pickupLocations ?? [];

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
                  Text(
                    '${item.product.name} x ${item.quantity}',
                    style: AppTextStyles.body2,
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

          // Location Dropdown
          if (pickupLocations.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This farmer has not set up any pickup locations yet.',
                style: TextStyle(color: AppColors.error),
              ),
            )
          else
            DropdownButtonFormField<PickupLocation>(
              initialValue: controller.selectedLocation,
              decoration: InputDecoration(
                labelText: 'Select Pickup Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              items: pickupLocations.map((loc) {
                return DropdownMenuItem(
                  value: loc,
                  child: Text(loc.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  controller.selectedLocation = val;
                  controller.selectedDate =
                      null; // Reset date/time on location change
                  controller.selectedTime = null;
                });
              },
            ),

          if (controller.selectedLocation != null) ...[
            const SizedBox(height: 16),
            Text(
              controller.selectedLocation!.address,
              style: AppTextStyles.body2Secondary,
            ),
            if (controller.selectedLocation!.notes.isNotEmpty)
              Text(
                'Note: ${controller.selectedLocation!.notes}',
                style: AppTextStyles.caption,
              ),

            const SizedBox(height: 16),

            // Date Selection
            InkWell(
              onTap: () => _selectDate(controller),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Pickup Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  controller.selectedDate != null
                      ? '${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}'
                      : 'Select Date',
                  style: controller.selectedDate != null
                      ? AppTextStyles.body1
                      : AppTextStyles.body2Tertiary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time Selection
            InkWell(
              onTap: () => _selectTime(controller),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Pickup Time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                child: Text(
                  controller.selectedTime != null
                      ? controller.selectedTime!.format(context)
                      : 'Select Time',
                  style: controller.selectedTime != null
                      ? AppTextStyles.body1
                      : AppTextStyles.body2Tertiary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: controller.instructionsController,
            decoration: InputDecoration(
              labelText: 'Special Instructions (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(_PickupFormController controller) async {
    final location = controller.selectedLocation;
    if (location == null) return;

    final now = DateTime.now();
    // Pre-order rule: 24h advance? Keeping it simple or reused from old logic.
    // Old logic: now.add(Duration(days: 1))
    final minDate = now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 30)),
      selectableDayPredicate: (date) {
        // Check if dayOfWeek is in availableWindows
        // date.weekday: 1=Mon, 7=Sun.
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
        controller.selectedTime = null; // Reset time as windows might differ
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

    // Filter windows for the selected day
    final windows = location.availableWindows
        .where((w) => w.dayOfWeek == date.weekday)
        .toList();
    if (windows.isEmpty) {
      return; // Should not happen due to selectableDayPredicate
    }

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
      // Validate time
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
          Text('Total Amount', style: AppTextStyles.h4),
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
      child: Text(
        'Confirm Pre-Order',
        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }

  void _onConfirmCheckout() {
    // Validate all controllers
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login');
      return;
    }

    // Check if any farmer section is incomplete
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

    // Build pickup details map
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

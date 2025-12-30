import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/blocs/cart/cart.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/auth/auth_state.dart';

class PreOrderCheckoutPage extends StatefulWidget {
  const PreOrderCheckoutPage({super.key});

  @override
  State<PreOrderCheckoutPage> createState() => _PreOrderCheckoutPageState();
}

class _PreOrderCheckoutPageState extends State<PreOrderCheckoutPage> {
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final minimumDate = now.add(const Duration(days: 1)); // 24 hours in advance

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? minimumDate,
      firstDate: minimumDate,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.info,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.info,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
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
          // Navigate to orders page
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

            final subtotal = state.totalPrice;
            final double total = subtotal;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(state, total),
                    const SizedBox(height: AppDimensions.spacingXL),
                    _buildPickupDetails(),
                    const SizedBox(height: AppDimensions.spacingXL),
                    _buildInfoNote(),
                    const SizedBox(height: AppDimensions.spacingXL),
                    _buildConfirmButton(total),
                    const SizedBox(height: AppDimensions.spacingXL),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartLoaded state, double total) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.spacingM),
          ...state.items.map(
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
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: AppTextStyles.h4.copyWith(color: AppColors.info),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetails() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup Details', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.spacingM),
          _buildTextField(
            controller: _locationController,
            label: 'Pickup Location',
            icon: Icons.location_on_outlined,
            hint: 'Enter pickup address',
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildDatePickerField(
            controller: _dateController,
            label: 'Pickup Date',
            icon: Icons.calendar_today_outlined,
            hint: 'Select date',
            onTap: _selectDate,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildDatePickerField(
            controller: _timeController,
            label: 'Pickup Time',
            icon: Icons.access_time,
            hint: 'Select time',
            onTap: _selectTime,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildTextField(
            controller: _instructionsController,
            label: 'Special Instructions (Optional)',
            hint: 'Any special requests or dietary notes...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTextStyles.body2Secondary),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body2Tertiary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTextStyles.body2Secondary),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body2Tertiary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: Icon(
              icon ?? Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.infoContainerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pre-orders must be placed at least 24 hours in advance. You\'ll receive a confirmation email with pickup details.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.customerPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(double total) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (authState is AuthAuthenticated) {
                context.read<CartBloc>().add(
                  CheckoutCart(
                    customerId: authState.userId!,
                    customerName: authState.displayName ?? 'Customer',
                    pickupLocation: _locationController.text,
                    pickupDate: _dateController.text,
                    pickupTime: _timeController.text,
                    specialInstructions: _instructionsController.text,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please log in to complete checkout'),
                  ),
                );
                context.push('/login');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            'Confirm Pre-Order - ₱${total.toStringAsFixed(2)}',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

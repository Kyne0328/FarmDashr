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

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _instructionsController.dispose();
    super.dispose();
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
            const double serviceFee = 2.99;
            final double tax = subtotal * 0.08;
            final double total = subtotal + serviceFee + tax;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(state, subtotal, serviceFee, tax, total),
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

  Widget _buildOrderSummary(
    CartLoaded state,
    double subtotal,
    double serviceFee,
    double tax,
    double total,
  ) {
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
          _buildSummaryRow('Subtotal', subtotal),
          _buildSummaryRow('Service Fee', serviceFee),
          _buildSummaryRow('Tax (8%)', tax),
          const SizedBox(height: 8),
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

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2Secondary),
          Text('₱${amount.toStringAsFixed(2)}', style: AppTextStyles.body2),
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
          _buildTextField(
            controller: _dateController,
            label: 'Pickup Date',
            icon: Icons.calendar_today_outlined,
            hint: 'Select date',
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildTextField(
            controller: _timeController,
            label: 'Pickup Time',
            icon: Icons.access_time,
            hint: 'Select time',
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

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0E1FF)),
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
                color: const Color(0xFF1347E5),
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
                final cartState = context.read<CartBloc>().state;
                final firstProduct =
                    (cartState as CartLoaded).items.first.product;

                context.read<CartBloc>().add(
                  CheckoutCart(
                    customerId: authState.userId!,
                    customerName: authState.displayName ?? 'Customer',
                    farmerId: firstProduct.farmerId,
                    farmerName: firstProduct.farmerName,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

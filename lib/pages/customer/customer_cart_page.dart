import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/blocs/cart/cart.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/data/models/cart_item.dart';

class CustomerCartPage extends StatelessWidget {
  const CustomerCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
          title: Text('Your Cart', style: AppTextStyles.h3),
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: () {
                context.read<CartBloc>().add(const ClearCart());
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is CartLoaded) {
              final items = state.items;

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      Text('Your cart is empty', style: AppTextStyles.h3),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        'Add some fresh products to get started!',
                        style: AppTextStyles.body2Secondary,
                      ),
                    ],
                  ),
                );
              }

              final subtotal = state.totalPrice;
              const double serviceFee = 2.99;
              final double tax = subtotal * 0.08;
              final double total = subtotal + serviceFee + tax;

              return ListView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.spacingM),
                    itemBuilder: (context, index) {
                      return _CartItemWidget(item: items[index]);
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),
                  _CartSummary(
                    subtotal: subtotal,
                    serviceFee: serviceFee,
                    tax: tax,
                    total: total,
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),
                  ElevatedButton(
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        context.read<CartBloc>().add(
                          CheckoutCart(
                            customerId: authState.userId!,
                            customerName: authState.displayName ?? 'Customer',
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to checkout'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue to Pre-Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final CartItem item;

  const _CartItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              image: item.product.imageUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item.product.imageUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.product.imageUrls.isEmpty
                ? const Icon(Icons.image, color: AppColors.textTertiary)
                : null,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () {
                        context.read<CartBloc>().add(
                          RemoveFromCart(item.product.id),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  item.product.category.displayName,
                  style: AppTextStyles.body2Secondary,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedTotal,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () {
                              context.read<CartBloc>().add(
                                DecrementCartItem(item.product.id),
                              );
                            },
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              context.read<CartBloc>().add(
                                IncrementCartItem(item.product.id),
                              );
                            },
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double subtotal;
  final double serviceFee;
  final double tax;
  final double total;

  const _CartSummary({
    required this.subtotal,
    required this.serviceFee,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', amount: subtotal),
          const SizedBox(height: AppDimensions.spacingM),
          _SummaryRow(label: 'Service Fee', amount: serviceFee),
          const SizedBox(height: AppDimensions.spacingM),
          _SummaryRow(label: 'Tax (8%)', amount: tax),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
            child: Divider(height: 1),
          ),
          _SummaryRow(label: 'Total', amount: total, isTotal: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

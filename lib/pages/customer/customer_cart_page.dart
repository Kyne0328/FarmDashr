import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/blocs/cart/cart.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:farmdashr/presentation/extensions/product_category_extension.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/presentation/widgets/common/confirmation_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/core/utils/responsive.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({super.key});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  @override
  void initState() {
    super.initState();
    // Refresh cart data to get latest product prices and stock
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartBloc>().add(const RefreshCart());
    });
  }

  void _showClearCartConfirmation(BuildContext context, int itemCount) async {
    final confirmed = await ConfirmationDialog.showClearCart(
      context,
      itemCount: itemCount,
    );

    if (confirmed == true && context.mounted) {
      HapticService.warning();
      context.read<CartBloc>().add(const ClearCart());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
        } else if (state is CartCheckoutPartialSuccess) {
          // Partial success - some orders placed, some failed
          SnackbarHelper.showInfo(
            context,
            state.message,
            duration: const Duration(seconds: 5),
          );
        } else if (state is CartOperationSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
        } else if (state is CartError) {
          SnackbarHelper.showError(context, state.message);
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
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                final itemCount = state is CartLoaded ? state.items.length : 0;
                return TextButton(
                  onPressed: itemCount > 0
                      ? () => _showClearCartConfirmation(context, itemCount)
                      : null,
                  child: Text(
                    'Clear All',
                    style: AppTextStyles.actionDestructive,
                  ),
                );
              },
            ),
            const SizedBox(width: AppDimensions.spacingS),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoading) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.maxContentWidth(context),
                  ),
                  child: SkeletonLoaders.verticalList(
                    cardBuilder: SkeletonLoaders.cartItem,
                    itemCount: 3,
                  ),
                ),
              );
            }

            if (state is CartLoaded) {
              final items = state.items;

              if (items.isEmpty) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.maxContentWidth(context),
                    ),
                    child: EmptyStateWidget.cart(
                      onBrowse: () => context.go('/customer-browse'),
                    ),
                  ),
                );
              }

              final subtotal = state.totalPrice;
              final double total = subtotal;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.maxContentWidth(context),
                  ),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.horizontalPadding(context),
                      vertical: AppDimensions.paddingL,
                    ),
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
                      _CartSummary(total: total),
                      const SizedBox(height: AppDimensions.spacingXL),
                      ElevatedButton(
                        onPressed: () {
                          // Check for any stock issues
                          final hasStockIssues = state.hasStockIssues;

                          if (hasStockIssues) {
                            HapticService.warning();
                            SnackbarHelper.showError(
                              context,
                              'Please remove or update out-of-stock items before checking out.',
                            );
                            return;
                          }

                          HapticService.heavy();
                          context.push('/pre-order-checkout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.hasStockIssues
                              ? AppColors.stateDisabled
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continue to Pre-Order',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is CartError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      Text('Something went wrong', style: AppTextStyles.h3),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        state.message,
                        style: AppTextStyles.body2Secondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<CartBloc>().add(const RefreshCart());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Handle CartInitial - show loading
            if (state is CartInitial) {
              return SkeletonLoaders.verticalList(
                cardBuilder: SkeletonLoaders.cartItem,
                itemCount: 3,
              );
            }

            // Handle CartOperationSuccess, CartCheckoutSuccess, CartCheckoutPartialSuccess - show empty cart
            if (state is CartOperationSuccess ||
                state is CartCheckoutSuccess ||
                state is CartCheckoutPartialSuccess) {
              return EmptyStateWidget.cart(
                onBrowse: () => context.go('/customer-browse'),
              );
            }

            // Truly unexpected state
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
                      image: CachedNetworkImageProvider(
                        item.product.imageUrls.first,
                      ),
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
                        HapticService.warning();
                        context.read<CartBloc>().add(
                          RemoveFromCart(item.product.id),
                        );
                      },
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
                Text(
                  item.product.category.displayName,
                  style: AppTextStyles.body2Secondary,
                ),
                if (item.quantity > item.product.currentStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Only ${item.product.currentStock} left',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                if (item.product.isOutOfStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Out of Stock',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedTotal,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.info,
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
                              HapticService.light();
                              context.read<CartBloc>().add(
                                DecrementCartItem(item.product.id),
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: AppTextStyles.labelMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed:
                                (item.quantity >= item.product.currentStock)
                                ? null
                                : () {
                                    HapticService.light();
                                    context.read<CartBloc>().add(
                                      IncrementCartItem(item.product.id),
                                    );
                                  },
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            color: (item.quantity >= item.product.currentStock)
                                ? AppColors.stateDisabled
                                : AppColors.textPrimary,
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
  final double total;

  const _CartSummary({required this.total});

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
        children: [_SummaryRow(label: 'Total', amount: total, isTotal: true)],
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
          style: isTotal
              ? AppTextStyles.labelLarge
              : AppTextStyles.body2Secondary,
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: isTotal
              ? AppTextStyles.price.copyWith(color: AppColors.primary)
              : AppTextStyles.body2,
        ),
      ],
    );
  }
}

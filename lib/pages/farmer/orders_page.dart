import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/presentation/widgets/common/pill_tab_bar.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/order_item_card.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';

// Data models
import 'package:farmdashr/data/models/order/order.dart';

// BLoC
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';

/// Orders Page - uses BLoC pattern for state management.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Uses the global OrderBloc provided in main.dart
    return const _OrdersPageContent();
  }
}

/// The actual content of the orders page.
class _OrdersPageContent extends StatefulWidget {
  const _OrdersPageContent();

  @override
  State<_OrdersPageContent> createState() => _OrdersPageContentState();
}

class _OrdersPageContentState extends State<_OrdersPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            SnackbarHelper.showSuccess(context, state.message);
          } else if (state is OrderError) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            // Loading state
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (state is OrderError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: AppTextStyles.body1),
                    const SizedBox(height: 16),
                    FarmButton(
                      label: 'Retry',
                      onPressed: () {
                        final userId = context.read<AuthBloc>().state.userId;
                        if (userId != null) {
                          context.read<OrderBloc>().add(
                            WatchFarmerOrders(userId),
                          );
                        } else {
                          context.read<OrderBloc>().add(const LoadOrders());
                        }
                      },
                      style: FarmButtonStyle.primary,
                      width: 120,
                      height: 48,
                    ),
                  ],
                ),
              );
            }

            // Loaded state
            if (state is OrderLoaded) {
              return _buildLoadedContent(context, state);
            }

            // Initial state - trigger load
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, OrderLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthBloc>().state.userId;
        if (userId != null) {
          context.read<OrderBloc>().add(WatchFarmerOrders(userId));
        } else {
          context.read<OrderBloc>().add(const LoadOrders());
        }
      },
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Orders', style: AppTextStyles.h3),
                    const SizedBox(height: AppDimensions.spacingXL),
                    _buildStatsGrid(
                      state.pendingCount,
                      state.preparingCount,
                      state.readyCount,
                      state.orders.where((o) {
                        final now = DateTime.now();
                        return o.createdAt.year == now.year &&
                            o.createdAt.month == now.month &&
                            o.createdAt.day == now.day;
                      }).length,
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverPersistentTabBarDelegate(
                controller: _tabController,
                tabs: [
                  'Current (${state.currentOrders.length})',
                  'History (${state.historyOrders.length})',
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersList(context, state.currentOrders),
            _buildOrdersList(context, state.historyOrders),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    int pendingCount,
    int preparingCount,
    int readyCount,
    int totalToday,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AnimatedOrderStatCard(
                label: 'Pending',
                value: pendingCount,
                backgroundColor: AppColors.warningBackground,
                borderColor: AppColors.warningLight,
                textColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _AnimatedOrderStatCard(
                label: 'Preparing',
                value: preparingCount,
                backgroundColor: AppColors.actionPurpleBackground,
                borderColor: AppColors.actionPurpleLight,
                textColor: AppColors.actionPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          children: [
            Expanded(
              child: _AnimatedOrderStatCard(
                label: 'Ready',
                value: readyCount,
                backgroundColor: AppColors.successBackground,
                borderColor: AppColors.successBorder,
                textColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _AnimatedOrderStatCard(
                label: 'Today',
                value: totalToday,
                backgroundColor: AppColors.infoBackground,
                borderColor: AppColors.infoBorder,
                textColor: AppColors.customerAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No orders found',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingL,
        AppDimensions.paddingM,
        AppDimensions.paddingL,
        AppDimensions.paddingXXL + 60, // Bottom padding for FAB/Scroll
      ),
      itemCount: orders.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.spacingM),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isTerminalState =
            order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.completed;

        return GestureDetector(
          onTap: () {
            if (!isTerminalState) {
              _showStatusMenu(context, order, (newStatus) {
                context.read<OrderBloc>().add(
                  UpdateOrderStatus(orderId: order.id, newStatus: newStatus),
                );
              });
            }
          },
          child: OrderItemCard(order: order, isFarmerView: true),
        );
      },
    );
  }
}

class _SliverPersistentTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final List<String> tabs;

  _SliverPersistentTabBarDelegate({
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      child: PillTabBarWithController(
        controller: controller,
        tabs: tabs,
        activeColor: AppColors.primary,
      ),
    );
  }

  @override
  double get maxExtent => 48.0 + (AppDimensions.paddingS * 2);

  @override
  double get minExtent => 48.0 + (AppDimensions.paddingS * 2);

  @override
  bool shouldRebuild(covariant _SliverPersistentTabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.tabs != tabs; // Rebuild if tabs (counts) change
  }
}

// ============================================================================
// Private Widgets & Methods
// ============================================================================

void _showStatusMenu(
  BuildContext context,
  Order order,
  Function(OrderStatus) onConfirm,
) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.hourglass_empty,
              color: AppColors.actionOrange,
            ),
            title: const Text('Mark as Pending'),
            onTap: () {
              HapticService.selection();
              Navigator.pop(context);
              onConfirm(OrderStatus.pending);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.moped_outlined,
              color: AppColors.actionPurple,
            ),
            title: const Text('Mark as Preparing'),
            onTap: () {
              HapticService.selection();
              Navigator.pop(context);
              onConfirm(OrderStatus.preparing);
            },
          ),
          ListTile(
            leading: Icon(Icons.check_circle_outline, color: AppColors.primary),
            title: const Text('Mark as Ready'),
            onTap: () {
              HapticService.selection();
              Navigator.pop(context);
              onConfirm(OrderStatus.ready);
            },
          ),
          ListTile(
            leading: const Icon(Icons.done_all, color: AppColors.info),
            title: const Text('Mark as Completed'),
            onTap: () {
              HapticService.selection();
              Navigator.pop(context);
              _showCompleteConfirmationDialog(context, onConfirm);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close, color: AppColors.error),
            title: const Text('Cancel Order'),
            onTap: () {
              HapticService.selection();
              Navigator.pop(context);
              _showCancelConfirmationDialog(context, onConfirm);
            },
          ),
        ],
      ),
    ),
  );
}

void _showCompleteConfirmationDialog(
  BuildContext context,
  Function(OrderStatus) onConfirm,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: const BoxDecoration(
                color: AppColors.infoBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.done_all_rounded,
                color: AppColors.info,
                size: 40,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            Text(
              'Complete this Order?',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'This will mark the order as completed. This action cannot be undone.',
              style: AppTextStyles.body2Secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXXL),
            SizedBox(
              width: double.infinity,
              child: FarmButton(
                label: 'Complete Order',
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onConfirm(OrderStatus.completed);
                },
                style: FarmButtonStyle.primary,
                backgroundColor: AppColors.info,
                isFullWidth: true,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            SizedBox(
              width: double.infinity,
              child: FarmButton(
                label: 'No, Keep as Ready',
                onPressed: () => Navigator.pop(dialogContext),
                style: FarmButtonStyle.ghost,
                textColor: AppColors.textSecondary,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showCancelConfirmationDialog(
  BuildContext context,
  Function(OrderStatus) onConfirm,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: const BoxDecoration(
                color: AppColors.errorBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            Text(
              'Cancel this Order?',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'Are you sure? This will mark the order as cancelled and cannot be reversed.',
              style: AppTextStyles.body2Secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXXL),
            SizedBox(
              width: double.infinity,
              child: FarmButton(
                label: 'Cancel Order',
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onConfirm(OrderStatus.cancelled);
                },
                style: FarmButtonStyle.danger,
                isFullWidth: true,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            SizedBox(
              width: double.infinity,
              child: FarmButton(
                label: 'No, Keep Order',
                onPressed: () => Navigator.pop(dialogContext),
                style: FarmButtonStyle.ghost,
                textColor: AppColors.textSecondary,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// Private Widgets
// ============================================================================

/// Animated order stat card with counting animation
class _AnimatedOrderStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _AnimatedOrderStatCard({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: borderColor,
          width: AppDimensions.borderWidthThick,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: textColor)),
          const SizedBox(height: AppDimensions.spacingXS),
          // Animated counter
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                '$animatedValue',
                style: AppTextStyles.priceLarge.copyWith(color: textColor),
              );
            },
          ),
        ],
      ),
    );
  }
}

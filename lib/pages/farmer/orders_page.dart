import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';

// Data models
import 'package:farmdashr/data/models/order/order.dart';

// Shared widgets
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/presentation/widgets/common/pill_tab_bar.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';

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
  bool _showCurrentOrders = true;

  /// Animation controller for page sections
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Staggered animations: Header, Stats, Tabs, Order List
    _fadeAnimations = List.generate(4, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(4, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // BlocListener for showing snackbars on success/error
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            SnackbarHelper.showSuccess(context, state.message);
          } else if (state is OrderError) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        // BlocBuilder for rebuilding UI based on state
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
    final currentOrders = state.currentOrders;
    final historyOrders = state.historyOrders;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Dispatch WatchFarmerOrders event on pull-to-refresh
                final userId = context.read<AuthBloc>().state.userId;
                if (userId != null) {
                  context.read<OrderBloc>().add(WatchFarmerOrders(userId));
                } else {
                  context.read<OrderBloc>().add(const LoadOrders());
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildAnimatedSection(
                      0,
                      Text('Orders', style: AppTextStyles.h3),
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Stats Cards Row - with animated counters
                    _buildAnimatedSection(
                      1,
                      _buildStatsGrid(
                        state.pendingCount,
                        state.preparingCount,
                        state.readyCount,
                        state.orders.length,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Tab Buttons with animated switching
                    _buildAnimatedSection(
                      2,
                      _buildTabButtons(
                        currentOrders.length,
                        historyOrders.length,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Order Cards List with animated content switch
                    _buildAnimatedSection(
                      3,
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildOrdersList(
                          context,
                          _showCurrentOrders ? currentOrders : historyOrders,
                          key: ValueKey(_showCurrentOrders),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildTabButtons(int currentCount, int historyCount) {
    return PillTabBar(
      tabs: const ['Current', 'History'],
      selectedIndex: _showCurrentOrders ? 0 : 1,
      onTabChanged: (index) {
        HapticService.selection();
        setState(() => _showCurrentOrders = index == 0);
      },
      showCounts: true,
      counts: [currentCount, historyCount],
      activeColor: AppColors.primary,
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    List<Order> orders, {
    Key? key,
  }) {
    if (orders.isEmpty) {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No orders found',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      key: key,
      children: orders.asMap().entries.map((entry) {
        final index = entry.key;
        final order = entry.value;
        // Determine if order is in a terminal state (not modifiable)
        final isTerminalState =
            order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.completed;

        // Staggered animation for each order card
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: _OrderCard(
              order: order,
              // Only allow status updates for non-terminal orders
              onStatusUpdate: isTerminalState
                  ? null
                  : (newStatus) {
                      // Dispatch UpdateOrderStatus event
                      context.read<OrderBloc>().add(
                        UpdateOrderStatus(
                          orderId: order.id,
                          newStatus: newStatus,
                        ),
                      );
                    },
            ),
          ),
        );
      }).toList(),
    );
  }
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
            duration: const Duration(milliseconds: 800),
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

/// Order card with press animation
class _OrderCard extends StatefulWidget {
  final Order order;
  final Function(OrderStatus)? onStatusUpdate;

  const _OrderCard({required this.order, this.onStatusUpdate});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _pressController.forward();

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    HapticService.selection();
    context.push(
      '/order-detail',
      extra: {'order': widget.order, 'isFarmerView': true},
    );
  }

  void _onTapCancel() => _pressController.reverse();

  Color _getStatusTextColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.actionOrange;
      case OrderStatus.preparing:
        return AppColors.actionPurple;
      case OrderStatus.ready:
        return AppColors.primaryDark;
      case OrderStatus.completed:
        return AppColors.infoDark;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.preparing:
        return Icons.moped_outlined;
      case OrderStatus.ready:
        return Icons.check_circle_outline;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.close;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(
              color: AppColors.border,
              width: AppDimensions.borderWidthThick,
            ),
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
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORD-${widget.order.id.substring(0, widget.order.id.length >= 6 ? 6 : widget.order.id.length).toUpperCase()}',
                        style: AppTextStyles.body1,
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        widget.order.customerName,
                        style: AppTextStyles.body2Secondary,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onStatusUpdate != null
                        ? () => _showStatusMenu(context)
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge.fromOrderStatus(
                          widget.order.status,
                          icon: _getStatusIcon(widget.order.status),
                        ),
                        if (widget.onStatusUpdate != null) ...[
                          const SizedBox(width: AppDimensions.spacingXS),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: _getStatusTextColor(widget.order.status),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // Date/Time Row
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: _formatDateTime(widget.order.createdAt),
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // Time ago Row
              _InfoRow(icon: Icons.access_time, text: widget.order.timeAgo),
              const SizedBox(height: AppDimensions.spacingM),

              if (widget.order.pickupLocation != null) ...[
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: 'Pickup: ${widget.order.pickupLocation}',
                ),
                const SizedBox(height: AppDimensions.spacingS),
                _InfoRow(
                  icon: Icons.event,
                  text:
                      '${widget.order.pickupDate} at ${widget.order.pickupTime}',
                ),
                const SizedBox(height: AppDimensions.spacingM),
              ],

              // Divider
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.spacingM),

              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.order.itemCount} items',
                    style: AppTextStyles.body2Tertiary,
                  ),
                  Text(
                    widget.order.formattedAmount,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
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
                widget.onStatusUpdate?.call(OrderStatus.pending);
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
                widget.onStatusUpdate?.call(OrderStatus.preparing);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
              ),
              title: const Text('Mark as Ready'),
              onTap: () {
                HapticService.selection();
                Navigator.pop(context);
                widget.onStatusUpdate?.call(OrderStatus.ready);
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all, color: AppColors.info),
              title: const Text('Mark as Completed'),
              onTap: () {
                HapticService.selection();
                Navigator.pop(context);
                _showCompleteConfirmationDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.error),
              title: const Text('Cancel Order'),
              onTap: () {
                HapticService.selection();
                Navigator.pop(context);
                _showCancelConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteConfirmationDialog(BuildContext context) {
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
                    widget.onStatusUpdate?.call(OrderStatus.completed);
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

  void _showCancelConfirmationDialog(BuildContext context) {
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
                    widget.onStatusUpdate?.call(OrderStatus.cancelled);
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconS, color: AppColors.textTertiary),
        const SizedBox(width: AppDimensions.spacingS),
        Text(text, style: AppTextStyles.body2Tertiary),
      ],
    );
  }
}

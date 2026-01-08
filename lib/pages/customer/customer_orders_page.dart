import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/presentation/widgets/common/pill_tab_bar.dart';
import 'package:farmdashr/presentation/widgets/common/order_item_card.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/auth/auth_state.dart';
import 'package:farmdashr/core/utils/responsive.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Uses the global OrderBloc provided in main.dart
    return const _CustomerOrdersContent();
  }
}

class _CustomerOrdersContent extends StatefulWidget {
  const _CustomerOrdersContent();

  @override
  State<_CustomerOrdersContent> createState() => _CustomerOrdersContentState();
}

class _CustomerOrdersContentState extends State<_CustomerOrdersContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start watching orders for the current customer
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && _customerId != authState.userId) {
      _customerId = authState.userId;
      context.read<OrderBloc>().add(WatchCustomerOrders(_customerId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthInitial || authState is AuthLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authState.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Please log in to view orders',
                style: AppTextStyles.body1,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, state) {
                      if (state is OrderLoading) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: Responsive.maxContentWidth(context),
                            ),
                            child: SkeletonLoaders.verticalList(
                              cardBuilder: SkeletonLoaders.orderCard,
                              itemCount: 3,
                            ),
                          ),
                        );
                      }
                      if (state is OrderError) {
                        return Center(child: Text(state.message));
                      }
                      if (state is OrderLoaded) {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersList(state.currentOrders),
                            _buildOrdersList(state.historyOrders),
                          ],
                        );
                      }
                      return SkeletonLoaders.verticalList(
                        cardBuilder: SkeletonLoaders.orderCard,
                        itemCount: 3,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: Container(
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Orders', style: AppTextStyles.h1),
              const SizedBox(height: AppDimensions.spacingM),
              PillTabBarWithController(
                controller: _tabController,
                tabs: const ['Active', 'Completed'],
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: EmptyStateWidget.noOrders(
            onBrowse: () => context.go('/customer-browse'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_customerId != null) {
          context.read<OrderBloc>().add(WatchCustomerOrders(_customerId!));
          await Future.delayed(const Duration(milliseconds: 500));
        }
      },
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
            itemCount: orders.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppDimensions.spacingM),
            itemBuilder: (context, index) =>
                OrderItemCard(order: orders[index]),
          ),
        ),
      ),
    );
  }
}

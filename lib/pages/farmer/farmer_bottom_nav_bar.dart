import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

/// Navigation item enum for farmer pages
enum FarmerNavItem {
  home,
  orders,
  inventory,
  profile;

  String get label {
    switch (this) {
      case FarmerNavItem.home:
        return 'Home';
      case FarmerNavItem.orders:
        return 'Orders';
      case FarmerNavItem.inventory:
        return 'Inventory';
      case FarmerNavItem.profile:
        return 'Profile';
    }
  }

  /// Outlined icon for inactive state
  IconData get icon {
    switch (this) {
      case FarmerNavItem.home:
        return Icons.home_outlined;
      case FarmerNavItem.orders:
        return Icons.receipt_long_outlined;
      case FarmerNavItem.inventory:
        return Icons.inventory_2_outlined;
      case FarmerNavItem.profile:
        return Icons.person_outline;
    }
  }

  /// Filled icon for active state
  IconData get activeIcon {
    switch (this) {
      case FarmerNavItem.home:
        return Icons.home;
      case FarmerNavItem.orders:
        return Icons.receipt_long;
      case FarmerNavItem.inventory:
        return Icons.inventory_2;
      case FarmerNavItem.profile:
        return Icons.person;
    }
  }

  String get route {
    switch (this) {
      case FarmerNavItem.home:
        return '/farmer-home-page';
      case FarmerNavItem.orders:
        return '/orders-page';
      case FarmerNavItem.inventory:
        return '/inventory-page';
      case FarmerNavItem.profile:
        return '/profile-page';
    }
  }
}

/// Shared bottom navigation bar for all farmer pages.
/// Features smooth animations for active state transitions.
class FarmerBottomNavBar extends StatelessWidget {
  final FarmerNavItem currentItem;

  const FarmerBottomNavBar({super.key, required this.currentItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: FarmerNavItem.values.map((item) {
              return Expanded(
                child: _AnimatedNavItem(
                  item: item,
                  isActive: item == currentItem,
                  onTap: () {
                    if (item != currentItem) {
                      context.go(item.route);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Animated navigation item with smooth transitions
class _AnimatedNavItem extends StatefulWidget {
  final FarmerNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animated scale for active state
              AnimatedScale(
                scale: widget.isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    widget.isActive ? widget.item.activeIcon : widget.item.icon,
                    key: ValueKey(widget.isActive),
                    size: 24,
                    color: widget.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Label with animated color
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.navLabel.copyWith(
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                child: Text(widget.item.label, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 4),
              // Active indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: 4,
                width: widget.isActive ? 4 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

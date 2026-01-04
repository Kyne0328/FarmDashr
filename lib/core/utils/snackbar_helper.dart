import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

class SnackbarHelper {
  static const Duration _defaultDuration = Duration(seconds: 4);

  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    // Using a dark neutral or primary color for info often looks better than bright blue
    _show(
      context,
      message,
      backgroundColor: AppColors.textPrimary,
      icon: Icons.info_outline,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    // Use removeCurrentSnackBar to immediately clear the current one
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: AppDimensions.iconS),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body2.copyWith(color: Colors.white),
              ),
            ),
            // Inline action button to avoid extra height from SnackBarAction
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(width: AppDimensions.spacingS),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onActionPressed();
                },
                child: Text(
                  actionLabel,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        duration: duration ?? _defaultDuration,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
      ),
    );
  }

  /// Shows a notification-style snackbar at the TOP of the screen
  /// Used for in-app push notifications when the app is in foreground
  static void showNotification(
    BuildContext context, {
    required String title,
    required String body,
    IconData? icon,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    // Use removeCurrentSnackBar to prevent stacking
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationOverlay(
        title: title,
        body: body,
        icon: icon ?? Icons.notifications_active_outlined,
        onTap: () {
          overlayEntry.remove();
          onTap?.call();
        },
        onDismiss: () => overlayEntry.remove(),
        duration: duration ?? const Duration(seconds: 5),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

/// Overlay widget for top notification
class _TopNotificationOverlay extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopNotificationOverlay({
    required this.title,
    required this.body,
    required this.icon,
    this.onTap,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_TopNotificationOverlay> createState() =>
      _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<_TopNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppDimensions.paddingS,
      left: AppDimensions.paddingM,
      right: AppDimensions.paddingM,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: AppColors.primary,
                        size: AppDimensions.iconM,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: AppDimensions.iconS,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

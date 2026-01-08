import 'package:flutter/material.dart';

/// Responsive design utilities for adapting layouts across different screen sizes.
///
/// Breakpoints:
/// - Mobile: < 600px
/// - Tablet: 600px - 899px
/// - Desktop: >= 900px
class Responsive {
  Responsive._(); // Private constructor

  // Breakpoint values
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  /// Returns true if the screen width is less than 600px (mobile).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  /// Returns true if the screen width is between 600px and 899px (tablet).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns true if the screen width is 900px or more (desktop).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Returns a value based on the current screen size.
  ///
  /// Example:
  /// ```dart
  /// final padding = Responsive.value<double>(
  ///   context,
  ///   mobile: 16,
  ///   tablet: 24,
  ///   desktop: 32,
  /// );
  /// ```
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Returns the maximum content width for the current screen size.
  /// On mobile, returns full width. On tablet/desktop, returns a constrained width.
  static double maxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (isDesktop(context)) {
      return 600; // Max width on desktop
    }
    if (isTablet(context)) {
      return screenWidth * 0.8; // 80% width on tablet
    }
    return screenWidth; // Full width on mobile
  }

  /// Returns responsive horizontal padding.
  static double horizontalPadding(BuildContext context) {
    return value<double>(context, mobile: 16, tablet: 32, desktop: 48);
  }

  /// Returns the number of grid columns based on screen width.
  static int gridColumns(BuildContext context) {
    return value<int>(context, mobile: 2, tablet: 3, desktop: 4);
  }
}

/// A widget that builds different layouts based on screen size.
///
/// Example:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return (desktop ?? tablet ?? mobile)(context);
    }
    if (Responsive.isTablet(context)) {
      return (tablet ?? mobile)(context);
    }
    return mobile(context);
  }
}

/// A convenience widget that constrains content width on larger screens
/// and centers it horizontally.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? Responsive.maxContentWidth(context);
    final effectivePadding =
        padding ??
        EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}

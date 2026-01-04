import 'package:flutter/services.dart';

/// Centralized haptic feedback utility for consistent tactile responses.
///
/// Use these methods to provide haptic feedback for different interactions:
/// - [light] - Subtle feedback for selections and toggles
/// - [medium] - Standard feedback for button taps
/// - [heavy] - Strong feedback for important actions
/// - [success] - Positive feedback for completed actions
/// - [warning] - Alert feedback for destructive actions
///   - [selection] - Minimal feedback for list selections
///   - [impact] - Generic impact feedback
class HapticService {
  HapticService._();

  /// Light impact - for selections, toggles, minor interactions
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for standard button taps
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Selection changed - minimal feedback for list selections
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Generic impact feedback
  static void impact() {
    HapticFeedback.mediumImpact();
  }

  /// Success feedback - for completed actions (add to cart, order placed)
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// Warning feedback - for destructive actions (delete, clear)
  static void warning() {
    HapticFeedback.heavyImpact();
  }

  /// Error feedback - for failed actions
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// Vibrate pattern - for errors or important alerts
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}

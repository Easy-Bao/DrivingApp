import 'package:material_ui/material_ui.dart';

/// Shared interaction helpers for quiet hairline controls that suppress noisy
/// touch splashes while preserving accessible keyboard focus rings.
class AppQuietInteraction._() {
  static WidgetStateProperty<Color> focusOverlay(
    Color color, {
    double alpha = 0.12,
  }) {
    return WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.focused)
          ? color.withValues(alpha: alpha)
          : Colors.transparent,
    );
  }

  static ButtonStyle iconButtonStyle(
    ColorScheme colorScheme, {
    Color? foregroundColor,
    Color? overlayBaseColor,
    double focusAlpha = 0.12,
    OutlinedBorder? shape,
    EdgeInsetsGeometry? padding,
  }) {
    return IconButton.styleFrom(
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      shape: shape,
      padding: padding,
      enableFeedback: false,
      splashFactory: NoSplash.splashFactory,
    ).copyWith(
      overlayColor: focusOverlay(
        overlayBaseColor ?? colorScheme.primary,
        alpha: focusAlpha,
      ),
    );
  }

  static ButtonStyle textButtonStyle(
    ColorScheme colorScheme, {
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry? alignment,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
        alpha: 0.42,
      ),
      padding: padding,
      alignment: alignment,
      enableFeedback: false,
      splashFactory: NoSplash.splashFactory,
    ).copyWith(overlayColor: focusOverlay(colorScheme.primary));
  }
}

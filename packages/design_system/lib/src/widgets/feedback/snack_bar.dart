import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

enum AppSnackBarTone { success, info, warning, error }

class AppSnackBar._() {
  static const Duration defaultDuration = Duration(seconds: 4);
  static const Duration actionDuration = Duration(seconds: 6);

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarTone? tone,
    bool isError = false,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
    EdgeInsetsGeometry? margin,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final colorScheme = context.colorScheme;
    final semanticColors = context.semanticColors;
    final resolvedTone =
        tone ?? (isError ? AppSnackBarTone.error : AppSnackBarTone.success);
    final (bgColor, fgColor, icon) = switch (resolvedTone) {
      AppSnackBarTone.success => (
        semanticColors.success,
        semanticColors.onSuccess,
        LucideIcons.circle_check,
      ),
      AppSnackBarTone.info => (
        colorScheme.inverseSurface,
        colorScheme.onInverseSurface,
        LucideIcons.info,
      ),
      AppSnackBarTone.warning => (
        semanticColors.warning,
        semanticColors.onWarning,
        LucideIcons.triangle_alert,
      ),
      AppSnackBarTone.error => (
        colorScheme.error,
        colorScheme.onError,
        LucideIcons.circle_alert,
      ),
    };

    final hasAction = actionLabel != null && onAction != null;
    final resolvedDuration =
        duration ?? (hasAction ? actionDuration : defaultDuration);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      duration: resolvedDuration,
      margin: margin,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      content: Semantics(
        container: true,
        liveRegion: true,
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, size: 18, color: fgColor)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      action: hasAction
          ? SnackBarAction(
              label: actionLabel,
              textColor: fgColor,
              onPressed: onAction,
            )
          : null,
    );

    messenger.showSnackBar(snackBar);
  }
}

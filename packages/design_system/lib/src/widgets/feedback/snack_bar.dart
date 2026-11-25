import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class AppSnackBar._() {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final colorScheme = context.colorScheme;
    final fgColor = isError
        ? colorScheme.onError
        : colorScheme.onInverseSurface;
    final bgColor = isError ? colorScheme.error : colorScheme.inverseSurface;

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      duration: duration,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      content: Row(
        children: [
          Icon(
            isError ? LucideIcons.circle_alert : LucideIcons.circle_check,
            size: 18,
            color: fgColor,
          ),
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
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: fgColor,
              onPressed: () => onAction?.call(),
            )
          : null,
    );

    messenger.showSnackBar(snackBar);
  }
}

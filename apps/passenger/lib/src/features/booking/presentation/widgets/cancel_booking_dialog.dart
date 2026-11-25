import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const CancelBookingDialog({
  super.key,
  this.isActiveRequest = false,
  this.destinationName,
}) extends StatelessWidget {
  final bool isActiveRequest;
  final String? destinationName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final destination = destinationName?.trim() ?? '';
    final title = isActiveRequest
        ? 'Cancel ride request?'
        : 'Cancel driver search?';
    final message = isActiveRequest
        ? destination.isNotEmpty
              ? 'Your ride request to $destination will be canceled and you will need to start a new search.'
              : 'Your ride request will be canceled and you will need to start a new search.'
        : destination.isNotEmpty
        ? 'Stop looking for drivers to $destination? You can start a new booking anytime.'
        : 'Stop looking for nearby drivers? You can start a new booking anytime.';
    final keepLabel = isActiveRequest ? 'Keep waiting' : 'Keep searching';
    final confirmLabel = isActiveRequest ? 'Cancel request' : 'Cancel search';

    return AlertDialog(
      backgroundColor: colors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colors.outlineVariant),
      ),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Icon(
          isActiveRequest ? LucideIcons.circle_alert : LucideIcons.search_x,
          size: 20,
          color: colors.onSurface,
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: context.textStyles.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: context.textStyles.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
          height: 1.45,
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          key: const ValueKey<String>('confirm-cancel-booking-button'),
          onPressed: () => Navigator.pop(context, true),
          style:
              TextButton.styleFrom(
                foregroundColor: colors.error,
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size(0, AppSize.minimumTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? colors.error.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
              ),
          child: Text(confirmLabel),
        ),
        FilledButton(
          key: const ValueKey<String>('keep-booking-button'),
          onPressed: () => Navigator.pop(context, false),
          style:
              FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size(0, AppSize.minimumTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? colors.onPrimary.withValues(alpha: 0.16)
                      : Colors.transparent,
                ),
              ),
          child: Text(keepLabel),
        ),
      ],
    );
  }
}

Future<bool> showCancelBookingDialog(
  BuildContext context, {
  bool isActiveRequest = false,
  String? destinationName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => CancelBookingDialog(
      isActiveRequest: isActiveRequest,
      destinationName: destinationName,
    ),
  );
  return confirmed ?? false;
}

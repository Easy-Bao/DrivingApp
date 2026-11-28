import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

enum BookingAuthAction() {
  signIn,
  signUp,
}

Future<BookingAuthAction?> showBookingAuthBottomSheet(
  BuildContext context, {
  String title = 'Sign in to book a ride',
  String message = 'Sign in or create an account to see your route and fare. Your trip details are saved and ready once you sign in.',
}) {
  return showModalBottomSheet<BookingAuthAction>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    barrierColor: context.colorScheme.onSurface.withValues(alpha: 0.54),
    useSafeArea: true,
    builder: (_) => BookingAuthBottomSheet(title: title, message: message),
  );
}

class const BookingAuthBottomSheet({
  super.key,
  this.title = 'Sign in to book a ride',
  this.message = 'Sign in or create an account to see your route and fare. Your trip details are saved and ready once you sign in.',
}) extends StatelessWidget {
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.lock, size: 22, color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: context.textStyles.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(BookingAuthAction.signIn),
                style:
                    FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 0,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      minimumSize: const Size.fromHeight(AppSize.controlHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(BookingAuthAction.signUp),
                style:
                    OutlinedButton.styleFrom(
                      backgroundColor: colors.surfaceContainerLowest,
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outlineVariant),
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      minimumSize: const Size.fromHeight(AppSize.controlHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      textStyle: context.textStyles.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                    ),
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

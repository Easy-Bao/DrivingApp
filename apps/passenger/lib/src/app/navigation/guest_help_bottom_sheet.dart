import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

enum GuestHelpAction { resetPassword, termsOfService }

Future<GuestHelpAction?> showGuestHelpBottomSheet(BuildContext context) {
  return showModalBottomSheet<GuestHelpAction>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colorScheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    barrierColor: context.colorScheme.onSurface.withValues(alpha: 0.54),
    useSafeArea: true,
    builder: (_) => const GuestHelpBottomSheet(),
  );
}

class const GuestHelpBottomSheet({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textStyles = context.textStyles;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Need help?',
                          style: textStyles.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Recover your account or review EasyRide terms.',
                        style: textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  key: const ValueKey<String>('guest-help-close'),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  style:
                      IconButton.styleFrom(
                        foregroundColor: colors.onSurfaceVariant,
                        minimumSize: const Size(
                          AppSize.minimumTouchTarget,
                          AppSize.minimumTouchTarget,
                        ),
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? colors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                      ),
                  icon: const Icon(LucideIcons.x, size: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              thickness: 1,
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSettingsNavigationTile(
              icon: LucideIcons.lock,
              title: 'Reset password',
              subtitle: 'Recover access to an existing account',
              onTap: () =>
                  Navigator.of(context).pop(GuestHelpAction.resetPassword),
            ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 52,
              color: colors.outlineVariant.withValues(alpha: 0.65),
            ),
            AppSettingsNavigationTile(
              icon: LucideIcons.file_text,
              title: 'Terms of Service',
              subtitle: 'Rides, payments, and account policies',
              onTap: () =>
                  Navigator.of(context).pop(GuestHelpAction.termsOfService),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              key: const ValueKey<String>('guest-help-emergency-notice'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        LucideIcons.circle_alert,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Not for emergencies. If you need urgent assistance, contact your local emergency services directly.',
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

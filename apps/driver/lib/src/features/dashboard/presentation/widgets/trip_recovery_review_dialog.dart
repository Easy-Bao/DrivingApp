import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const TripRecoveryReviewDialog({super.key, required this.isInTransit})
    extends StatelessWidget {
  final bool isInTransit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.circle_alert,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Review this trip',
                textAlign: TextAlign.center,
                style: textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isInTransit
                    ? 'This trip has been open longer than expected. Confirm the trip status with your passenger before continuing.'
                    : 'This pickup has been waiting longer than expected. Check with the passenger, then continue or use the cancellation action on the trip screen.',
                textAlign: TextAlign.center,
                style: textStyles.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: AppSize.controlHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.focused)) {
                            return colorScheme.onPrimary.withValues(
                              alpha: 0.16,
                            );
                          }
                          return Colors.transparent;
                        }),
                      ),
                  child: const Text('Open trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

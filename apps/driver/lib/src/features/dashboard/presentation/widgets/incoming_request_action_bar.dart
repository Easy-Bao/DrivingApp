import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

class const IncomingRequestActionBar({
  super.key,
  required this.horizontalPadding,
  required this.awaitingAssignment,
  required this.submittingAccept,
  required this.submittingDecline,
  required this.canAccept,
  required this.canDecline,
  required this.onAccept,
  required this.onDecline,
}) extends StatelessWidget {
  final double horizontalPadding;
  final bool awaitingAssignment;
  final bool submittingAccept;
  final bool submittingDecline;
  final bool canAccept;
  final bool canDecline;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.canvasColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.lg,
          horizontalPadding,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (awaitingAssignment) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Confirming your trip…',
                  textAlign: TextAlign.center,
                  style: textStyles.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: AppSize.controlHeight,
                child: FilledButton(
                  key: const ValueKey<String>('driver-request-accept'),
                  onPressed: canAccept ? onAccept : null,
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
                  child: Text(
                    submittingAccept ? 'Sending response…' : 'Accept ride',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              SizedBox(
                height: AppSize.controlHeight,
                child: OutlinedButton(
                  key: const ValueKey<String>('driver-request-decline'),
                  onPressed: canDecline ? onDecline : null,
                  style:
                      OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: colorScheme.outlineVariant),
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.focused)) {
                            return colorScheme.primary.withValues(alpha: 0.12);
                          }
                          return Colors.transparent;
                        }),
                      ),
                  child: Text(submittingDecline ? 'Declining…' : 'Decline'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

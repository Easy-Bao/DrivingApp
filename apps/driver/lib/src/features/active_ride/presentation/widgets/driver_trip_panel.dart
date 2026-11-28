import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_confirmation_slider.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_passenger_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

enum DriverTripBusyAction { none, advancing, canceling, markingNoShow }

class const DriverTripPanel({
  super.key,
  required this.state,
  required this.pickup,
  required this.dropoff,
  required this.fare,
  required this.progress,
  this.progressListenable,
  required this.isBusy,
  this.busyAction = DriverTripBusyAction.none,
  required this.unreadCount,
  required this.onProgressChanged,
  required this.onAdvance,
  required this.onChat,
  required this.onCancel,
  required this.onNoShow,
  this.noShowRemaining,
  this.notice,
  this.onDismissNotice,
}) extends StatelessWidget {
  final RideState state;
  final String pickup;
  final String dropoff;
  final double fare;
  final double progress;
  final ValueListenable<double>? progressListenable;
  final bool isBusy;
  final DriverTripBusyAction busyAction;
  final int unreadCount;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onAdvance;
  final VoidCallback onChat;
  final VoidCallback onCancel;
  final VoidCallback? onNoShow;
  final Duration? noShowRemaining;
  final String? notice;
  final VoidCallback? onDismissNotice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final waiting = state.isWaitingAtPickup;
    final inTransit = state is TripInProgress;
    final seconds = state.waitTimeSecondsOr(0);
    final waitLabel =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final remaining = ((noShowRemaining?.inMilliseconds ?? 0) / 1000).ceil();
    final effectiveBusyAction = busyAction != DriverTripBusyAction.none
        ? busyAction
        : (isBusy ? DriverTripBusyAction.advancing : DriverTripBusyAction.none);
    final isAdvancing = effectiveBusyAction == DriverTripBusyAction.advancing;
    final isCanceling = effectiveBusyAction == DriverTripBusyAction.canceling;
    final isMarkingNoShow =
        effectiveBusyAction == DriverTripBusyAction.markingNoShow;
    final isAnyBusy =
        isBusy || effectiveBusyAction != DriverTripBusyAction.none;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: waiting
                  ? _TripMilestonePill(
                      key: const ValueKey<String>('driver-milestone-arrived'),
                      icon: LucideIcons.circle_check,
                      label: 'Arrived at pickup',
                      backgroundColor: context.semanticColors.successContainer,
                      foregroundColor:
                          context.semanticColors.onSuccessContainer,
                    )
                  : inTransit
                  ? _TripMilestonePill(
                      key: const ValueKey<String>(
                        'driver-milestone-in-transit',
                      ),
                      icon: LucideIcons.navigation,
                      label: 'Trip in progress',
                      backgroundColor: context.semanticColors.infoContainer,
                      foregroundColor: context.semanticColors.onInfoContainer,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey<String>('driver-milestone-en-route'),
                    ),
            ),
            Text(
              waiting
                  ? 'Waiting for passenger · $waitLabel'
                  : inTransit
                  ? 'Head to destination'
                  : 'Head to pickup',
              style: textStyles.titleLarge?.tabular.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              inTransit ? dropoff : pickup,
              style: textStyles.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Agreed fare',
                    style: textStyles.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatPesoAmount(fare),
                  style: textStyles.titleMedium?.tabular.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            RidePassengerRow(
              name: state.passengerNameOr('Passenger'),
              subtitle: waiting
                  ? 'Meet at pickup'
                  : inTransit
                  ? 'Passenger on board'
                  : 'Your passenger',
              unreadCount: unreadCount,
              onChat: onChat,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (notice case final message?) ...[
              _TripNotice(message: message, onDismiss: onDismissNotice),
              const SizedBox(height: AppSpacing.md),
            ],
            if (waiting)
              SizedBox(
                height: AppSize.controlHeight,
                child: FilledButton(
                  key: const ValueKey<String>('driver-trip-start-button'),
                  onPressed: isAnyBusy ? null : onAdvance,
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
                  child: Text(isAdvancing ? 'Starting trip…' : 'Start trip'),
                ),
              )
            else if (progressListenable case final listenable?)
              ValueListenableBuilder<double>(
                valueListenable: listenable,
                builder: (context, sliderProgress, _) => RideConfirmationSlider(
                  progress: sliderProgress,
                  label: inTransit
                      ? 'Slide to complete trip'
                      : 'Slide when you arrive',
                  releaseLabel: inTransit
                      ? 'Release to complete'
                      : 'Release to confirm',
                  processingLabel: inTransit
                      ? 'Completing trip…'
                      : 'Confirming arrival…',
                  hint: inTransit
                      ? 'Swipe right to complete the trip.'
                      : 'Swipe right to confirm arrival.',
                  isProcessing: isAdvancing,
                  enabled: !isAnyBusy,
                  onProgressChanged: onProgressChanged,
                  onConfirmed: onAdvance,
                ),
              )
            else
              RideConfirmationSlider(
                progress: progress,
                label: inTransit
                    ? 'Slide to complete trip'
                    : 'Slide when you arrive',
                releaseLabel: inTransit
                    ? 'Release to complete'
                    : 'Release to confirm',
                processingLabel: inTransit
                    ? 'Completing trip…'
                    : 'Confirming arrival…',
                hint: inTransit
                    ? 'Swipe right to complete the trip.'
                    : 'Swipe right to confirm arrival.',
                isProcessing: isAdvancing,
                enabled: !isAnyBusy,
                onProgressChanged: onProgressChanged,
                onConfirmed: onAdvance,
              ),
            if (!inTransit) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                style:
                    OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      side: BorderSide.none,
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
                onPressed: isAnyBusy ? null : onCancel,
                child: Text(isCanceling ? 'Canceling…' : 'Cancel ride'),
              ),
            ],
            if (waiting && noShowRemaining != null)
              if (onNoShow != null)
                TextButton(
                  onPressed: isAnyBusy ? null : onNoShow,
                  style:
                      TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.focused)) {
                            return colorScheme.primary.withValues(alpha: 0.12);
                          }
                          return Colors.transparent;
                        }),
                      ),
                  child: Text(
                    isMarkingNoShow
                        ? 'Recording no-show…'
                        : 'Passenger did not arrive',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'No-show available in ${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: textStyles.bodySmall?.tabular.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class const _TripMilestonePill({
  super.key,
  required this.icon,
  required this.label,
  required this.backgroundColor,
  required this.foregroundColor,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(icon, size: 14, color: foregroundColor),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(
                  child: Text(
                    label,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class const _TripNotice({required this.message, this.onDismiss})
    extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                LucideIcons.circle_alert,
                size: 17,
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                style: IconButton.styleFrom(
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                ),
                icon: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: colors.onErrorContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

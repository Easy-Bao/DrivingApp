import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_confirmation_slider.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_passenger_row.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

class const DriverTripPanel({
  super.key,
  required this.state,
  required this.pickup,
  required this.dropoff,
  required this.fare,
  required this.progress,
  required this.isBusy,
  required this.unreadCount,
  required this.onProgressChanged,
  required this.onAdvance,
  required this.onChat,
  required this.onCancel,
  required this.onNoShow,
  this.noShowRemaining,
  this.actionError,
}) extends StatelessWidget {
  final RideState state;
  final String pickup;
  final String dropoff;
  final double fare;
  final double progress;
  final bool isBusy;
  final int unreadCount;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onAdvance;
  final VoidCallback onChat;
  final VoidCallback onCancel;
  final VoidCallback? onNoShow;
  final Duration? noShowRemaining;
  final String? actionError;

  @override
  Widget build(BuildContext context) {
    final waiting = state.isWaitingAtPickup;
    final inTransit = state is TripInProgress;
    final seconds = state.waitTimeSecondsOr(0);
    final waitLabel =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final remaining = ((noShowRemaining?.inMilliseconds ?? 0) / 1000).ceil();
    return Material(
      color: context.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              waiting
                  ? 'Waiting for passenger · $waitLabel'
                  : inTransit
                  ? 'Head to destination'
                  : 'Head to pickup',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              inTransit ? dropoff : pickup,
              style: context.textStyles.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Agreed fare',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  formatPesoAmount(fare),
                  style: context.textStyles.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
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
            if (actionError != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  actionError!,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (waiting)
              FilledButton(
                onPressed: isBusy ? null : onAdvance,
                child: Text(isBusy ? 'Starting trip…' : 'Start trip'),
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
                isProcessing: isBusy,
                onProgressChanged: onProgressChanged,
                onConfirmed: onAdvance,
              ),
            if (!inTransit) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: context.colorScheme.onSurface,
                    width: 1.5,
                  ),
                ),
                onPressed: isBusy ? null : onCancel,
                child: const Text('Cancel ride'),
              ),
            ],
            if (waiting && noShowRemaining != null)
              if (onNoShow != null)
                TextButton(
                  onPressed: isBusy ? null : onNoShow,
                  child: const Text('Passenger did not arrive'),
                )
              else
                Text(
                  'No-show available in ${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

import 'package:driver/src/features/active_ride/presentation/widgets/ride_passenger_row.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class const WaitingPassengerPanel({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.passengerName,
  required this.waitFormatted,
  required this.fare,
  this.isStartingTrip = false,
  this.includeStartTripButton = true,
  required this.unreadChatMessagesCount,
  required this.onStartTripPressed,
  required this.onCallPressed,
  required this.onChatPressed,
}) extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String passengerName;
  final String waitFormatted;
  final double fare;
  final bool isStartingTrip;
  final bool includeStartTripButton;
  final int unreadChatMessagesCount;
  final VoidCallback onStartTripPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onChatPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Waiting at pickup · $waitFormatted',
                style: context.textStyles.titleSmall,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatPesoAmount(fare),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: context.colorScheme.outlineVariant),
        const SizedBox(height: 14),
        CompactRouteTimeline(pickup: pickup, dropoff: dropoff),
        const SizedBox(height: 14),
        Divider(height: 1, color: context.colorScheme.outlineVariant),
        const SizedBox(height: 12),
        RidePassengerRow(
          name: passengerName,
          subtitle: 'Meet at pickup',
          unreadCount: unreadChatMessagesCount,
          onCall: onCallPressed,
          onChat: onChatPressed,
        ),
        if (includeStartTripButton) ...[
          const SizedBox(height: 12),
          WaitingPassengerStartTripButton(
            isStartingTrip: isStartingTrip,
            onPressed: onStartTripPressed,
          ),
        ],
      ],
    );
  }
}

class const WaitingPassengerStartTripButton({
  super.key,
  required this.isStartingTrip,
  required this.onPressed,
}) extends StatelessWidget {
  final bool isStartingTrip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isStartingTrip ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.primary,
          foregroundColor: context.colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        child: isStartingTrip
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colorScheme.onPrimary,
                ),
              )
            : const Text('Start Trip'),
      ),
    );
  }
}

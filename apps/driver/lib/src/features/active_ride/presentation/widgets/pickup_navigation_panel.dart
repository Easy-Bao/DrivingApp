import 'package:driver/src/features/active_ride/presentation/widgets/ride_passenger_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_confirmation_slider.dart';

class const PickupNavigationPanel({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.passengerName,
  required this.distance,
  required this.fare,
  required this.sliderValue,
  this.isConfirmingArrival = false,
  this.isCancelling = false,
  required this.unreadChatMessagesCount,
  required this.onSliderChanged,
  required this.onSliderCompleted,
  required this.onCancelPressed,
  required this.onCallPressed,
  required this.onChatPressed,
}) extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String passengerName;
  final double distance;
  final double fare;
  final double sliderValue;
  final bool isConfirmingArrival;
  final bool isCancelling;
  final int unreadChatMessagesCount;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onSliderCompleted;
  final VoidCallback onCancelPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onChatPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        10,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statusPill(context)),
              const SizedBox(width: 8),
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
          const SizedBox(height: 10),
          CompactRouteTimeline(pickup: pickup, dropoff: dropoff),
          const SizedBox(height: 10),
          RidePassengerRow(
            name: passengerName,
            subtitle: '${DistanceFormatter.fromKilometers(distance)} to pickup',
            unreadCount: unreadChatMessagesCount,
            onCall: onCallPressed,
            onChat: onChatPressed,
          ),
          const SizedBox(height: 12),
          _arrivalSlider(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isCancelling ? null : onCancelPressed,
              child: Text(isCancelling ? 'Cancelling…' : 'Cancel ride'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.semanticColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.navigation,
            size: 13,
            color: context.semanticColors.success,
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Heading to pickup',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.semanticColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrivalSlider() {
    return RideConfirmationSlider(
      progress: sliderValue,
      label: 'Slide when you arrive',
      releaseLabel: 'Release to confirm',
      processingLabel: 'Confirming arrival…',
      hint: 'Swipe right to confirm arrival.',
      isProcessing: isConfirmingArrival,
      onProgressChanged: onSliderChanged,
      onConfirmed: onSliderCompleted,
    );
  }
}

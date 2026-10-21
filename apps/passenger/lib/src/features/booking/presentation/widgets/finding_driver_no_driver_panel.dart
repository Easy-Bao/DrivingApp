import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_status_sheet.dart';

class const FindingDriverNoDriverPanel({
  super.key,
  required this.fare,
  required this.destination,
  this.pickupAddress,
  this.rideType,
  this.requestId,
  this.requestExpired = false,
  this.onRequestRidePressed,
  required this.onRetryPressed,
  required this.onCancelPressed,
  this.isCanceling = false,
}) extends StatelessWidget {
  final double fare;
  final Place destination;
  final String? pickupAddress;
  final String? rideType;
  final String? requestId;
  final bool requestExpired;
  final VoidCallback? onRequestRidePressed;
  final VoidCallback onRetryPressed;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    return FindingDriverStatusSheet(
      eyebrow: requestExpired ? 'Request ended' : 'Driver search',
      title: requestExpired
          ? 'No driver accepted in time'
          : 'No nearby drivers yet',
      message: requestExpired
          ? 'This request expired. You can check again or start a new request.'
          : 'You can request a ride anyway. Nearby drivers can still respond while your request is open.',
      statusIcon: LucideIcons.search,
      statusColor: Theme.of(context).colorScheme.primary,
      destination: destination.name,
      pickupAddress: pickupAddress,
      rideType: rideType,
      requestId: requestId,
      fare: fare,
      primaryAction: onRequestRidePressed ?? onRetryPressed,
      primaryActionLabel: onRequestRidePressed == null
          ? 'Try again'
          : 'Request a ride',
      primaryActionIcon: LucideIcons.search,
      secondaryAction: onRetryPressed,
      secondaryActionLabel: 'Check again',
      secondaryActionIcon: LucideIcons.refresh_cw,
      onCancelPressed: onCancelPressed,
      isCanceling: isCanceling,
    );
  }
}

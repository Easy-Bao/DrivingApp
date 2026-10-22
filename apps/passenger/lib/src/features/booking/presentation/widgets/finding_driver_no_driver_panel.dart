import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_status_sheet.dart';

class const FindingDriverNoDriverPanel({
  super.key,
  required this.fare,
  required this.destination,
  this.pickupAddress,

  this.bookingReference,
  this.requestExpired = false,
  required this.onRetryPressed,
  required this.onCancelPressed,
  this.isCanceling = false,
}) extends StatelessWidget {
  final double fare;
  final Place destination;
  final String? pickupAddress;

  final String? bookingReference;
  final bool requestExpired;
  final VoidCallback onRetryPressed;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    return FindingDriverStatusSheet(
      title: requestExpired ? 'No driver found' : 'No drivers nearby',
      message: requestExpired
          ? 'Your request has ended. Try searching again for an available driver.'
          : 'We couldn’t find an available driver nearby. Try searching again in a moment.',
      statusIcon: LucideIcons.search_x,
      statusColor: Theme.of(context).colorScheme.onSurface,
      destination: destination.name,
      pickupAddress: pickupAddress,

      bookingReference: bookingReference,
      fare: fare,
      primaryAction: onRetryPressed,
      primaryActionLabel: 'Retry search',
      onCancelPressed: onCancelPressed,
      isCanceling: isCanceling,
    );
  }
}

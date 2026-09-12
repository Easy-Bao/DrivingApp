import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_status_sheet.dart';

class const FindingDriverNoDriverPanelWidget({
  super.key,
  required this.rideType,
  required this.fare,
  required this.destination,
  required this.onRetryPressed,
  required this.onCancelPressed,
  this.isCanceling = false,
}) extends StatelessWidget {
  final String rideType;
  final double fare;
  final Place destination;
  final VoidCallback onRetryPressed;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    return FindingDriverStatusSheet(
      eyebrow: 'Driver search',
      title: 'No driver found',
      message:
          'No $rideType drivers are available nearby right now. Try again when you’re ready.',
      statusIcon: LucideIcons.search,
      statusColor: Theme.of(context).colorScheme.primary,
      destination: destination.name,
      fare: fare,
      primaryAction: onRetryPressed,
      primaryActionLabel: 'Try again',
      primaryActionIcon: LucideIcons.refresh_cw,
      onCancelPressed: onCancelPressed,
      isCanceling: isCanceling,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_status_sheet.dart';

class const FindingDriverAvailabilityErrorPanelWidget({
  super.key,
  required this.message,
  required this.fare,
  required this.destination,
  required this.onRetryPressed,
  required this.onCancelPressed,
  this.isCanceling = false,
}) extends StatelessWidget {
  final String message;
  final double fare;
  final Place destination;
  final VoidCallback onRetryPressed;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    return FindingDriverStatusSheet(
      eyebrow: 'Connection issue',
      title: 'Driver search unavailable',
      message: message,
      statusIcon: LucideIcons.circle_alert,
      statusColor: Theme.of(context).colorScheme.error,
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

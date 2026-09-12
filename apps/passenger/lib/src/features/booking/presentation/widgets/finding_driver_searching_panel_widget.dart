import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_status_sheet.dart';

class const FindingDriverSearchingPanelWidget({
  super.key,
  required this.message,
  required this.rideType,
  required this.fare,
  required this.destination,
  this.pickupAddress,
  required this.dotAnimation,
  required this.onCancelPressed,
  this.isCanceling = false,
}) extends StatelessWidget {
  final String message;
  final String rideType;
  final double fare;
  final Place destination;
  final String? pickupAddress;
  final Animation<double> dotAnimation;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    return FindingDriverStatusSheet(
      eyebrow: 'Finding a driver',
      title: message,
      message: pickupAddress != null
          ? 'Your request is with nearby drivers. We’ll let you know as soon as one accepts.'
          : 'We’re checking nearby $rideType drivers for your ride.',
      statusIcon: LucideIcons.search,
      statusColor: Theme.of(context).colorScheme.primary,
      statusAnimation: dotAnimation,
      destination: destination.name,
      fare: fare,
      onCancelPressed: onCancelPressed,
      isCanceling: isCanceling,
    );
  }
}

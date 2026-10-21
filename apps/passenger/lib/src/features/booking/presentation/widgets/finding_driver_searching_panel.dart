import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_status_sheet.dart';

class const FindingDriverSearchingPanel({
  super.key,
  required this.message,
  required this.fare,
  required this.destination,
  this.pickupAddress,
  this.rideType,
  this.requestId,
  this.expiresAt,
  this.requestCreated = false,
  this.isSendingRequest = false,
  this.animate = true,
  this.refreshError,
  this.onRetryPressed,
  required this.dotAnimation,
  required this.onCancelPressed,
  this.isCanceling = false,
}) extends StatelessWidget {
  final String message;
  final double fare;
  final Place destination;
  final String? pickupAddress;
  final String? rideType;
  final String? requestId;
  final DateTime? expiresAt;
  final bool requestCreated;
  final bool isSendingRequest;
  final bool animate;
  final String? refreshError;
  final VoidCallback? onRetryPressed;
  final Animation<double> dotAnimation;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    return FindingDriverStatusSheet(
      eyebrow: requestCreated
          ? 'Ride request'
          : isSendingRequest
          ? 'Sending request'
          : 'Driver availability',
      title: message,
      message: requestCreated
          ? 'Your request is open. We’ll update this screen when a driver responds.'
          : isSendingRequest
          ? 'We’re sending your request and will confirm when the server accepts it.'
          : 'We’re checking which drivers are currently nearby.',
      statusIcon: LucideIcons.search,
      statusColor: Theme.of(context).colorScheme.primary,
      statusAnimation: animate ? dotAnimation : null,
      destination: destination.name,
      pickupAddress: pickupAddress,
      rideType: rideType,
      requestId: requestId,
      footerMessage:
          refreshError ??
          (expiresAt == null
              ? null
              : 'Request expires at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(expiresAt!.toLocal()))}'),
      fare: fare,
      onCancelPressed: onCancelPressed,
      cancelLabel: isSendingRequest || requestCreated
          ? 'Cancel request'
          : 'Cancel search',
      secondaryAction: refreshError == null ? null : onRetryPressed,
      secondaryActionLabel: refreshError == null ? null : 'Retry update',
      secondaryActionIcon: LucideIcons.refresh_cw,
      isCanceling: isCanceling,
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';

class const SafetyReportButton({
  super.key,
  required this.rideId,
  this.bookingReference = '',
  this.driverName = '',
  this.vehiclePlate = '',
  this.vehicleType = '',
  required this.trackRepository,
}) extends StatelessWidget {
  final String? rideId;
  final String bookingReference;
  final String driverName;
  final String vehiclePlate;
  final String vehicleType;
  final TrackRepository trackRepository;

  @override
  Widget build(BuildContext context) {
    final canReport = rideId != null && rideId!.isNotEmpty;
    return Tooltip(
      message: 'Report a safety issue',
      child: TextButton.icon(
        onPressed: canReport
            ? () async {
                await showSafetyReportSheet(
                  context,
                  rideId: rideId!,
                  bookingReference: bookingReference,
                  driverName: driverName,
                  vehiclePlate: vehiclePlate,
                  vehicleType: vehicleType,
                  trackRepository: trackRepository,
                );
              }
            : null,
        icon: const Icon(LucideIcons.flag_triangle_right),
        label: const Text('Report an issue'),
      ),
    );
  }
}

Future<bool> showSafetyReportSheet(
  BuildContext context, {
  required String rideId,
  String bookingReference = '',
  String driverName = '',
  String vehiclePlate = '',
  String vehicleType = '',
  required TrackRepository trackRepository,
}) async {
  return showTripSafetyReportForm(
    context,
    title: 'Report a driver issue',
    reasons: _passengerSafetyReportOptions,
    tripSummary:
        driverName.trim().isNotEmpty || bookingReference.trim().isNotEmpty
        ? _ReportTripSummary(
            name: driverName,
            plate: vehiclePlate,
            vehicle: vehicleType,
            bookingReference: bookingReference,
          )
        : null,
    onSubmit: (category, description) async {
      final result = await trackRepository.createSafetyReportResult(
        rideId: rideId,
        category: category,
        description: description,
      );
      return result.fold((failure) => failure.message, (_) => null);
    },
  );
}

const _passengerSafetyReportOptions = <SafetyReportReason>[
  SafetyReportReason(value: 'unsafe_driving', label: 'Unsafe driving'),
  SafetyReportReason(value: 'driver_identity_mismatch', label: 'Wrong driver'),
  SafetyReportReason(value: 'vehicle_mismatch', label: 'Wrong vehicle'),
  SafetyReportReason(value: 'harassment', label: 'Harassment'),
  SafetyReportReason(value: 'threat_or_violence', label: 'Threat or violence'),
  SafetyReportReason(value: 'fare_dispute', label: 'Fare dispute'),
  SafetyReportReason(value: 'route_issue', label: 'Route issue'),
  SafetyReportReason(value: 'fraud', label: 'Suspected fraud'),
  SafetyReportReason(value: 'accident', label: 'Accident or injury'),
  SafetyReportReason(value: 'other', label: 'Other concern'),
];

class const _ReportTripSummary({
  required this.name,
  required this.plate,
  required this.vehicle,
  required this.bookingReference,
}) extends StatelessWidget {
  final String name;
  final String plate;
  final String vehicle;
  final String bookingReference;

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = [
      plate.trim(),
      vehicle.trim(),
    ].where((value) => value.isNotEmpty).join(' | ');
    final displayName = name.trim();
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (displayName.isNotEmpty) ...[
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.colorScheme.surface,
                    foregroundColor: context.colorScheme.onSurface,
                    child: Text(initials),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (vehicleLabel.isNotEmpty)
                          Text(
                            vehicleLabel,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (bookingReference.trim().isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: Divider(height: 1),
                ),
            ],
            if (bookingReference.trim().isNotEmpty)
              TripReference(id: bookingReference, compact: true),
          ],
        ),
      ),
    );
  }
}

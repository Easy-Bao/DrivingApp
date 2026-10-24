import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const SafetyReportButton({
  super.key,
  required this.rideId,
  this.bookingReference = '',
  required this.rideRepository,
}) extends StatelessWidget {
  final String? rideId;
  final String bookingReference;
  final RideRepository rideRepository;

  @override
  Widget build(BuildContext context) {
    final canReport = rideId != null && rideId!.isNotEmpty;
    return IconButton(
      onPressed: canReport
          ? () async {
              await showSafetyReportSheet(
                context,
                rideId: rideId!,
                bookingReference: bookingReference,
                rideRepository: rideRepository,
              );
            }
          : null,
      tooltip: 'Report a safety issue',
      icon: const Icon(LucideIcons.flag_triangle_right),
      color: context.colorScheme.error,
      constraints: const BoxConstraints(
        minWidth: AppSize.minimumTouchTarget,
        minHeight: AppSize.minimumTouchTarget,
      ),
    );
  }
}

Future<bool> showSafetyReportSheet(
  BuildContext context, {
  required String rideId,
  String bookingReference = '',
  required RideRepository rideRepository,
}) async {
  return showTripSafetyReportForm(
    context,
    title: 'Report a passenger issue',
    reasons: _driverSafetyReportOptions,
    tripSummary: bookingReference.trim().isNotEmpty
        ? TripReference(id: bookingReference, compact: true)
        : null,
    onSubmit: (category, description) async {
      final result = await rideRepository.createSafetyReportResult(
        rideId: rideId,
        category: category,
        description: description,
      );
      return result.fold((failure) => failure.message, (_) => null);
    },
  );
}

const _driverSafetyReportOptions = <SafetyReportReason>[
  SafetyReportReason(value: 'harassment', label: 'Passenger harassment'),
  SafetyReportReason(value: 'threat_or_violence', label: 'Threat or violence'),
  SafetyReportReason(value: 'non_payment', label: 'Cash not paid'),
  SafetyReportReason(value: 'property_damage', label: 'Property damage'),
  SafetyReportReason(
    value: 'prohibited_cargo',
    label: 'Prohibited or unsafe cargo',
  ),
  SafetyReportReason(value: 'fraud', label: 'Fraud or fake booking'),
  SafetyReportReason(value: 'no_show', label: 'Passenger no-show'),
  SafetyReportReason(value: 'accident', label: 'Accident or injury'),
  SafetyReportReason(value: 'other', label: 'Other serious concern'),
];

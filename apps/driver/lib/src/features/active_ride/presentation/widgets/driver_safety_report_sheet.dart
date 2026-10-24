import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const SafetyReportButton({
  super.key,
  required this.rideId,
  required this.rideRepository,
}) extends StatelessWidget {
  final String? rideId;
  final RideRepository rideRepository;

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
                  rideRepository: rideRepository,
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
  required RideRepository rideRepository,
}) async {
  return showTripSafetyReportForm(
    context,
    title: 'Report a passenger issue',
    reasons: _driverSafetyReportOptions,
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

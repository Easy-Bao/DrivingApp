import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';

class const SafetyReportButton({
  super.key,
  required this.rideId,
  this.driverName = '',
  this.vehiclePlate = '',
  this.vehicleType = '',
  required this.trackRepository,
}) extends StatelessWidget {
  final String? rideId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleType;
  final TrackRepository trackRepository;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final canReport = rideId != null && rideId!.isNotEmpty;
    return Tooltip(
      message: 'Report a safety issue',
      child: TextButton.icon(
        onPressed: canReport
            ? () async {
                await showSafetyReportSheet(
                  context,
                  rideId: rideId!,
                  driverName: driverName,
                  vehiclePlate: vehiclePlate,
                  vehicleType: vehicleType,
                  trackRepository: trackRepository,
                );
              }
            : null,
        style:
            TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? colors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
            ),
        icon: const Icon(LucideIcons.flag_triangle_right, size: 16),
        label: const Text('Report an issue'),
      ),
    );
  }
}

Future<bool> showSafetyReportSheet(
  BuildContext context, {
  required String rideId,
  String driverName = '',
  String vehiclePlate = '',
  String vehicleType = '',
  required TrackRepository trackRepository,
}) async {
  return showTripSafetyReportForm(
    context,
    title: 'Report a driver issue',
    reasons: _passengerSafetyReportOptions,
    tripSummary: driverName.trim().isNotEmpty
        ? _ReportTripSummary(
            name: driverName,
            plate: vehiclePlate,
            vehicle: vehicleType,
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
}) extends StatelessWidget {
  final String name;
  final String plate;
  final String vehicle;

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
    final colors = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (displayName.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: context.textStyles.titleSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (vehicleLabel.isNotEmpty)
                          Text(
                            vehicleLabel,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/ride_repository.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const SafetyReportButton({
  super.key,
  required this.rideId,
  required this.rideRepository,
}) extends StatefulWidget {
  final String? rideId;
  final RideRepository rideRepository;

  @override
  State<SafetyReportButton> createState() => _SafetyReportButtonState();
}

class _SafetyReportButtonState extends State<SafetyReportButton> {
  bool _hasReported = false;

  @override
  void didUpdateWidget(covariant SafetyReportButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rideId != oldWidget.rideId) {
      _hasReported = false;
    }
  }

  Future<void> _openReportSheet() async {
    final rideId = widget.rideId;
    if (rideId == null || rideId.isEmpty || _hasReported) return;
    final submitted = await showSafetyReportSheet(
      context,
      rideId: rideId,
      rideRepository: widget.rideRepository,
    );
    if (submitted && mounted) {
      setState(() => _hasReported = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasReported) {
      final semanticColors = context.semanticColors;
      return Semantics(
        container: true,
        liveRegion: true,
        child: Padding(
          key: const ValueKey('driver-safety-issue-reported'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.circle_check,
                  size: 16,
                  color: semanticColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Issue reported',
                  style: context.textStyles.labelLarge?.copyWith(
                    color: semanticColors.onSuccessContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final canReport = widget.rideId != null && widget.rideId!.isNotEmpty;
    return Tooltip(
      message: 'Report a safety issue',
      child: TextButton.icon(
        onPressed: canReport ? _openReportSheet : null,
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

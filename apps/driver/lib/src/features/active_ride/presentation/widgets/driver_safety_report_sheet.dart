import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

class const DriverSafetyReportButton({
  super.key,
  required this.rideId,
  required this.rideRepository,
}) extends StatelessWidget {
  final String? rideId;
  final DriverRideRepository rideRepository;

  @override
  Widget build(BuildContext context) {
    final canReport = rideId != null && rideId!.isNotEmpty;
    return IconButton(
      onPressed: canReport
          ? () async {
              final submitted = await showDriverSafetyReportSheet(
                context,
                rideId: rideId!,
                rideRepository: rideRepository,
              );
              if (submitted && context.mounted) {
                CustomToast.show(
                  context,
                  'Report submitted and linked to this ride.',
                );
              }
            }
          : null,
      tooltip: 'Report a safety issue',
      icon: const Icon(LucideIcons.flag_triangle_right),
      color: context.colorScheme.error,
      constraints: const BoxConstraints(
        minWidth: EasyRideSize.minimumTouchTarget,
        minHeight: EasyRideSize.minimumTouchTarget,
      ),
    );
  }
}

Future<bool> showDriverSafetyReportSheet(
  BuildContext context, {
  required String rideId,
  required DriverRideRepository rideRepository,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _DriverSafetyReportSheet(
          rideId: rideId,
          rideRepository: rideRepository,
        ),
      ) ??
      false;
}

class const _DriverSafetyReportOption({
  required this.value,
  required this.label,
}) {
  final String value;
  final String label;
}

const _driverSafetyReportOptions = <_DriverSafetyReportOption>[
  _DriverSafetyReportOption(value: 'harassment', label: 'Passenger harassment'),
  _DriverSafetyReportOption(
    value: 'threat_or_violence',
    label: 'Threat or violence',
  ),
  _DriverSafetyReportOption(value: 'non_payment', label: 'Cash not paid'),
  _DriverSafetyReportOption(value: 'property_damage', label: 'Property damage'),
  _DriverSafetyReportOption(
    value: 'prohibited_cargo',
    label: 'Prohibited or unsafe cargo',
  ),
  _DriverSafetyReportOption(value: 'fraud', label: 'Fraud or fake booking'),
  _DriverSafetyReportOption(value: 'no_show', label: 'Passenger no-show'),
  _DriverSafetyReportOption(value: 'accident', label: 'Accident or injury'),
  _DriverSafetyReportOption(value: 'other', label: 'Other serious concern'),
];

class const _DriverSafetyReportSheet({
  required this.rideId,
  required this.rideRepository,
}) extends StatefulWidget {
  final String rideId;
  final DriverRideRepository rideRepository;

  @override
  State<_DriverSafetyReportSheet> createState() =>
      _DriverSafetyReportSheetState();
}

class _DriverSafetyReportSheetState extends State<_DriverSafetyReportSheet> {
  final _descriptionController = TextEditingController();
  String? _category;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final category = _category;
    final description = _descriptionController.text.trim();
    if (_isSubmitting || category == null || description.isEmpty) {
      setState(
        () => _errorMessage = 'Choose a reason and describe what happened.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final result = await widget.rideRepository.createSafetyReportResult(
      rideId: widget.rideId,
      category: category,
      description: description,
    );
    if (!mounted) return;
    DomainFailure? failure;
    result.fold((value) => failure = value, (_) {});
    if (failure != null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = failure!.message;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EasyRideRadius.sheet),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              EasyRideSpacing.lg,
              EasyRideSpacing.lg,
              EasyRideSpacing.lg,
              EasyRideSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.flag_triangle_right,
                      color: context.colorScheme.error,
                    ),
                    const SizedBox(width: EasyRideSpacing.sm),
                    Expanded(
                      child: Text(
                        'Report a passenger issue',
                        style: context.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: EasyRideSpacing.xs),
                Text(
                  'Use this for safety or serious trip problems. The report is linked to the ride timeline.',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: EasyRideSpacing.md),
                EasyRideSelectField<String>(
                  key: const ValueKey('driver-safety-report-category'),
                  value: _category,
                  menuTitle: 'What happened?',
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    border: OutlineInputBorder(),
                  ),
                  options: [
                    for (final option in _driverSafetyReportOptions)
                      EasyRideSelectOption<String>(
                        value: option.value,
                        label: option.label,
                      ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _category = value),
                ),
                const SizedBox(height: EasyRideSpacing.md),
                TextField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Describe what happened',
                    hintText: 'Include useful details such as where and when it happened.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: EasyRideSpacing.xs),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: context.colorScheme.error),
                  ),
                ],
                const SizedBox(height: EasyRideSpacing.md),
                SizedBox(
                  height: EasyRideSize.controlHeight,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.send),
                    label: Text(
                      _isSubmitting ? 'Submitting…' : 'Submit report',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

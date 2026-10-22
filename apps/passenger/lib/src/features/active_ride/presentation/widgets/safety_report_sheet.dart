import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';

class const SafetyReportButton({
  super.key,
  required this.rideId,
  this.bookingReference = '',
  required this.trackRepository,
}) extends StatelessWidget {
  final String? rideId;
  final String bookingReference;
  final TrackRepository trackRepository;

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
                trackRepository: trackRepository,
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
  required TrackRepository trackRepository,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        showDragHandle: false,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _SafetyReportSheet(
          rideId: rideId,
          bookingReference: bookingReference,
          trackRepository: trackRepository,
        ),
      ) ??
      false;
}

class const _SafetyReportOption({required this.value, required this.label}) {
  final String value;
  final String label;
}

const _passengerSafetyReportOptions = <_SafetyReportOption>[
  _SafetyReportOption(value: 'unsafe_driving', label: 'Unsafe driving'),
  _SafetyReportOption(
    value: 'driver_identity_mismatch',
    label: 'Driver identity mismatch',
  ),
  _SafetyReportOption(
    value: 'vehicle_mismatch',
    label: 'Vehicle does not match',
  ),
  _SafetyReportOption(value: 'harassment', label: 'Harassment'),
  _SafetyReportOption(value: 'threat_or_violence', label: 'Threat or violence'),
  _SafetyReportOption(value: 'fare_dispute', label: 'Fare dispute'),
  _SafetyReportOption(value: 'route_issue', label: 'Route issue'),
  _SafetyReportOption(value: 'fraud', label: 'Fraud or suspicious behavior'),
  _SafetyReportOption(value: 'accident', label: 'Accident or injury'),
  _SafetyReportOption(value: 'other', label: 'Other serious concern'),
];

class const _SafetyReportSheet({
  required this.rideId,
  this.bookingReference = '',
  required this.trackRepository,
}) extends StatefulWidget {
  final String rideId;
  final String bookingReference;
  final TrackRepository trackRepository;

  @override
  State<_SafetyReportSheet> createState() => _SafetyReportSheetState();
}

class _SafetyReportSheetState extends State<_SafetyReportSheet> {
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
    final result = await widget.trackRepository.createSafetyReportResult(
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
          top: Radius.circular(AppRadius.sheet),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
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
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Report a driver issue',
                        style: context.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Use this for safety or serious trip problems. The report is linked to the ride timeline.',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TripReference(
                    id: widget.bookingReference,
                    label: 'Booking ID',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSelectField<String>(
                  key: const ValueKey('passenger-safety-report-category'),
                  value: _category,
                  menuTitle: 'What happened?',
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    border: OutlineInputBorder(),
                  ),
                  options: [
                    for (final option in _passengerSafetyReportOptions)
                      AppSelectOption<String>(
                        value: option.value,
                        label: option.label,
                      ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _category = value),
                ),
                const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: context.colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: AppSize.controlHeight,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text('Submitting…'),
                            ],
                          )
                        : const Text('Submit report'),
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

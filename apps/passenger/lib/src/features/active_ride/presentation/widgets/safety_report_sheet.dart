import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
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
    return IconButton(
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
  String driverName = '',
  String vehiclePlate = '',
  String vehicleType = '',
  required TrackRepository trackRepository,
}) async {
  final submitted =
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        showDragHandle: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (context) => _SafetyReportSheet(
          rideId: rideId,
          bookingReference: bookingReference,
          driverName: driverName,
          vehiclePlate: vehiclePlate,
          vehicleType: vehicleType,
          trackRepository: trackRepository,
        ),
      ) ??
      false;
  if (submitted && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Report submitted.')));
  }
  return submitted;
}

class const _SafetyReportOption({required this.value, required this.label}) {
  final String value;
  final String label;
}

const _passengerSafetyReportOptions = <_SafetyReportOption>[
  _SafetyReportOption(value: 'unsafe_driving', label: 'Unsafe driving'),
  _SafetyReportOption(value: 'driver_identity_mismatch', label: 'Wrong driver'),
  _SafetyReportOption(value: 'vehicle_mismatch', label: 'Wrong vehicle'),
  _SafetyReportOption(value: 'harassment', label: 'Harassment'),
  _SafetyReportOption(value: 'threat_or_violence', label: 'Threat or violence'),
  _SafetyReportOption(value: 'fare_dispute', label: 'Fare dispute'),
  _SafetyReportOption(value: 'route_issue', label: 'Route issue'),
  _SafetyReportOption(value: 'fraud', label: 'Suspected fraud'),
  _SafetyReportOption(value: 'accident', label: 'Accident or injury'),
  _SafetyReportOption(value: 'other', label: 'Other concern'),
];

class const _SafetyReportSheet({
  required this.rideId,
  this.bookingReference = '',
  this.driverName = '',
  this.vehiclePlate = '',
  this.vehicleType = '',
  required this.trackRepository,
}) extends StatefulWidget {
  final String rideId;
  final String bookingReference;
  final String driverName;
  final String vehiclePlate;
  final String vehicleType;
  final TrackRepository trackRepository;

  @override
  State<_SafetyReportSheet> createState() => _SafetyReportSheetState();
}

class _SafetyReportSheetState extends State<_SafetyReportSheet> {
  final _descriptionController = TextEditingController();
  String? _category;
  String? _errorMessage;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isSubmitting &&
      _category != null &&
      _descriptionController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final category = _category;
    final description = _descriptionController.text.trim();
    if (_isSubmitting) return;
    if (category == null || description.isEmpty) {
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
    final colors = context.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xs,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Report a driver issue',
                        style: context.textStyles.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tell us what happened on this trip.',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (widget.driverName.trim().isNotEmpty ||
                        widget.bookingReference.trim().isNotEmpty) ...[
                      _ReportTripSummary(
                        name: widget.driverName,
                        plate: widget.vehiclePlate,
                        vehicle: widget.vehicleType,
                        bookingReference: widget.bookingReference,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        'What happened?',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 0,
                      children: [
                        for (final option in _passengerSafetyReportOptions)
                          ChoiceChip(
                            key: ValueKey('report-reason-${option.value}'),
                            label: Text(option.label),
                            selected: _category == option.value,
                            onSelected: _isSubmitting
                                ? null
                                : (_) => setState(() {
                                    _category = option.value;
                                    _errorMessage = null;
                                  }),
                            selectedColor: colors.onSurface,
                            backgroundColor: colors.surface,
                            checkmarkColor: colors.surface,
                            labelStyle: context.textStyles.labelLarge?.copyWith(
                              color: _category == option.value
                                  ? colors.surface
                                  : colors.onSurface,
                            ),
                            side: BorderSide(
                              color: _category == option.value
                                  ? colors.onSurface
                                  : colors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            visualDensity: VisualDensity.standard,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      key: const ValueKey('report-details'),
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 2000,
                      enabled: !_isSubmitting,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() => _errorMessage = null),
                      decoration: const InputDecoration(
                        labelText: 'Details (required)',
                        hintText:
                            'Describe what happened, including where and when.',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_errorMessage != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _errorMessage!,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppSize.controlHeight,
                          ),
                          textStyle: context.textStyles.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: colors.onSurface,
                          foregroundColor: colors.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        onPressed: _canSubmit ? _submit : null,
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Flexible(child: Text('Submitting…')),
                                ],
                              )
                            : const Text('Submit report'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

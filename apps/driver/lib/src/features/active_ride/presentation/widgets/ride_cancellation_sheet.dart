import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

final class CancellationChoice {
  const CancellationChoice({required this.reason, this.details = ''});

  final String reason;
  final String details;
}

typedef CancellationSubmitCallback = Future<String?> Function(
  CancellationChoice choice,
);

class RideCancellationSheet extends StatefulWidget {
  const RideCancellationSheet({super.key, this.onSubmit});

  final CancellationSubmitCallback? onSubmit;

  static const Map<String, String> cancellationReasons = {
    'passenger_requested_cancellation': 'Passenger asked me to cancel',
    'passenger_unreachable': 'Passenger is unreachable',
    'pickup_inaccessible': 'Pickup location is inaccessible',
    'vehicle_problem': 'Vehicle problem',
    'medical_emergency': 'Medical emergency',
    'road_blocked': 'Road is blocked',
    'unsafe_pickup_location': 'Pickup location feels unsafe',
    'passenger_behavior_unsafe': 'Passenger behavior is unsafe',
    'accident': 'Accident',
    'unable_to_continue': 'Unable to continue',
    'other': 'Other (requires details)',
  };

  @override
  State<RideCancellationSheet> createState() => _RideCancellationSheetState();
}

class _RideCancellationSheetState extends State<RideCancellationSheet> {
  String? _selectedReason;
  String _details = '';
  String? _validationMessage;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting || _selectedReason == null) return;
    final details = _details.trim();
    if (_selectedReason == 'other' && details.isEmpty) {
      setState(() => _validationMessage = 'Add details when choosing Other.');
      return;
    }
    final choice = CancellationChoice(
      reason: _selectedReason!,
      details: details,
    );
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      Navigator.pop(context, choice);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _validationMessage = null;
    });
    final error = await onSubmit(choice);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, choice);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _validationMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textStyles = context.textStyles;
    final isOther = _selectedReason == 'other';

    return PopScope(
      canPop: !_isSubmitting,
      child: AppBottomSheetContainer(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm + 2,
          AppSpacing.xl,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel ride?',
                style: textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose the reason that best describes what happened.',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSelectField<String>.anchored(
                key: const ValueKey('driver-cancellation-reason-dropdown'),
                value: _selectedReason,
                menuTitle: 'Reason for cancellation',
                decoration: const InputDecoration(
                  labelText: 'Reason for cancellation',
                  hintText: 'Select a reason',
                ),
                options: [
                  for (final entry
                      in RideCancellationSheet.cancellationReasons.entries)
                    AppSelectOption<String>(
                      value: entry.key,
                      label: entry.value,
                    ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedReason = value;
                          _validationMessage = null;
                        });
                      },
              ),
              if (isOther) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const ValueKey('driver-cancellation-details'),
                  enabled: !_isSubmitting,
                  maxLength: 500,
                  maxLines: 3,
                  onChanged: (value) {
                    _details = value;
                    if (_validationMessage != null) {
                      setState(() => _validationMessage = null);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    hintText: 'Add enough detail for a later review.',
                  ),
                ),
              ],
              if (_validationMessage != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _validationMessage!,
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.75),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: ExcludeSemantics(
                        child: Icon(
                          LucideIcons.info,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'If the passenger is absent, use ',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                          children: [
                            TextSpan(
                              text: 'Passenger No-Show',
                              style: textStyles.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                            const TextSpan(
                              text: ' after the waiting timer finishes.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppSize.controlHeight,
                      child: OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: colors.onSurface,
                              side: BorderSide(color: colors.outlineVariant),
                              enableFeedback: false,
                              splashFactory: NoSplash.splashFactory,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                              textStyle: textStyles.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.focused)) {
                                  return colors.primary.withValues(alpha: 0.12);
                                }
                                return Colors.transparent;
                              }),
                            ),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Keep ride'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: AppSize.controlHeight,
                      child: FilledButton(
                        key: const ValueKey(
                          'confirm-driver-cancel-ride-button',
                        ),
                        style:
                            FilledButton.styleFrom(
                              backgroundColor: colors.error,
                              foregroundColor: colors.onError,
                              disabledBackgroundColor:
                                  colors.surfaceContainerHighest,
                              disabledForegroundColor: colors.onSurfaceVariant
                                  .withValues(alpha: 0.38),
                              elevation: 0,
                              enableFeedback: false,
                              splashFactory: NoSplash.splashFactory,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                              textStyle: textStyles.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.focused)) {
                                  return colors.onError.withValues(alpha: 0.16);
                                }
                                return Colors.transparent;
                              }),
                            ),
                        onPressed: _selectedReason == null || _isSubmitting
                            ? null
                            : () => unawaited(_submit()),
                        child: Text(
                          _isSubmitting ? 'Canceling…' : 'Cancel ride',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<CancellationChoice?> showRideCancellationSheet(
  BuildContext context, {
  CancellationSubmitCallback? onSubmit,
}) {
  return showModalBottomSheet<CancellationChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RideCancellationSheet(onSubmit: onSubmit),
  );
}

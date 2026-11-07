import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

final class CancellationChoice {
  const CancellationChoice({required this.reason, this.details = ''});

  final String reason;
  final String details;
}

class RideCancellationSheet extends StatefulWidget {
  const RideCancellationSheet({super.key});

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

  void _submit() {
    final details = _details.trim();
    if (_selectedReason == 'other' && details.isEmpty) {
      setState(() => _validationMessage = 'Add details when choosing Other.');
      return;
    }
    Navigator.pop(
      context,
      CancellationChoice(reason: _selectedReason!, details: details),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isOther = _selectedReason == 'other';
    final isDialog = ModalRoute.of(context) is DialogRoute;

    final content = Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: isDialog
            ? BorderRadius.circular(AppRadius.lg)
            : const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            isDialog ? AppSpacing.xl : AppSpacing.sm,
            AppSpacing.xl,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isDialog) ...[
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(
                        top: AppSpacing.xs,
                        bottom: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
                Text(
                  'Cancel ride?',
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose the reason that best describes what happened.',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
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
                  onChanged: (value) {
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
                  Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'If the passenger is absent, use ',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'Passenger No-Show',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
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
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.surfaceContainerHighest,
                            foregroundColor: colors.onSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            textStyle: context.textStyles.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Keep ride'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          key: const ValueKey(
                            'confirm-driver-cancel-ride-button',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.onSurface,
                            foregroundColor: colors.surface,
                            disabledBackgroundColor:
                                colors.surfaceContainerHighest,
                            disabledForegroundColor: colors.onSurfaceVariant
                                .withValues(alpha: 0.38),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            textStyle: context.textStyles.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: _selectedReason == null ? null : _submit,
                          child: const Text('Cancel ride'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isDialog) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: content,
      );
    }
    return content;
  }
}

Future<CancellationChoice?> showRideCancellationSheet(BuildContext context) {
  return showModalBottomSheet<CancellationChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: context.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => const RideCancellationSheet(),
  );
}

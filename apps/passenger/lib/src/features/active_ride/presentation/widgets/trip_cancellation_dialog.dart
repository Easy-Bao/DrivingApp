import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class TripCancellationDialog extends StatefulWidget {
  const TripCancellationDialog({super.key});

  static const Map<String, String> cancellationReasons = {
    'passenger_changed_mind': 'Changed my mind',
    'driver_taking_too_long': 'Driver is taking too long',
    'found_another_ride': 'Found another ride',
    'wrong_pickup_location': 'Wrong pickup location',
    'driver_asked_to_cancel': 'Driver asked to cancel',
    'driver_no_show': 'Driver did not arrive',
  };

  @override
  State<TripCancellationDialog> createState() => _TripCancellationDialogState();
}

class _TripCancellationDialogState extends State<TripCancellationDialog> {
  String? _selectedReason;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: context.colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    title: Text(
      'Cancel ride?',
      style: context.textStyles.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a reason so EasyRide can record what happened. No cancellation fee is collected in the app.',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Reason for cancellation',
              style: context.textStyles.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSelectField<String>.anchored(
              key: const ValueKey('cancellation-reason-dropdown'),
              value: _selectedReason,
              menuTitle: 'Reason for cancellation',
              style: context.textStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Select a reason',
                filled: true,
                fillColor: context.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              options: [
                for (final entry
                    in TripCancellationDialog.cancellationReasons.entries)
                  AppSelectOption(value: entry.key, label: entry.value),
              ],
              onChanged: (value) => setState(() => _selectedReason = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: context.colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text('Keep ride'),
      ),
      FilledButton(
        key: const ValueKey('confirm-cancel-ride-button'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        onPressed: _selectedReason == null
            ? null
            : () => Navigator.pop(context, _selectedReason),
        child: const Text('Cancel ride'),
      ),
    ],
  );
}

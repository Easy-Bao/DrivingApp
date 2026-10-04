import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

final class const DriverCancellationChoice({
  required this.reason,
  this.details = '',
}) {
  final String reason;
  final String details;
}

class DriverRideCancellationSheet extends StatefulWidget {
  const DriverRideCancellationSheet({super.key});

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
  State<DriverRideCancellationSheet> createState() =>
      _DriverRideCancellationSheetState();
}

class _DriverRideCancellationSheetState
    extends State<DriverRideCancellationSheet> {
  String? _selectedReason;
  String _details = '';
  String? _validationMessage;

  @override
  Widget build(BuildContext context) {
    final isOther = _selectedReason == 'other';
    return AlertDialog(
      backgroundColor: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
      ),
      title: Text(
        'Cancel ride?',
        style: context.textStyles.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the reason that best describes what happened. If the passenger is absent, use Passenger No-Show after the waiting timer finishes.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('driver-cancellation-reason-dropdown'),
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
              ),
              items: DriverRideCancellationSheet.cancellationReasons.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                  _validationMessage = null;
                });
              },
            ),
            if (isOther) ...[
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              Text(
                _validationMessage!,
                style: TextStyle(color: context.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep ride'),
        ),
        FilledButton(
          key: const ValueKey('confirm-driver-cancel-ride-button'),
          onPressed: _selectedReason == null
              ? null
              : () {
                  final details = _details.trim();
                  if (_selectedReason == 'other' && details.isEmpty) {
                    setState(
                      () => _validationMessage =
                          'Add details when choosing Other.',
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    DriverCancellationChoice(
                      reason: _selectedReason!,
                      details: details,
                    ),
                  );
                },
          child: const Text('Cancel ride'),
        ),
      ],
    );
  }
}

Future<DriverCancellationChoice?> showDriverRideCancellationSheet(
  BuildContext context,
) {
  return showDialog<DriverCancellationChoice>(
    context: context,
    builder: (_) => const DriverRideCancellationSheet(),
  );
}

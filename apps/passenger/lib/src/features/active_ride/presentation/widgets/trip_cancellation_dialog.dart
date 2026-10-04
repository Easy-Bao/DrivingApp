import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class TripCancellationDialog extends StatefulWidget {
  const TripCancellationDialog({super.key});

  static const Map<String, String> cancellationReasons = {
    'driver_taking_too_long': 'Driver is taking too long',
    'driver_asked_to_cancel': 'Driver asked to cancel',
    'wrong_pickup_location': 'Wrong pickup location',
    'passenger_changed_mind': 'Changed my mind',
    'found_another_ride': 'Found another ride',
    'driver_no_show': 'Driver did not arrive',
  };

  @override
  State<TripCancellationDialog> createState() => _TripCancellationDialogState();
}

class _TripCancellationDialogState extends State<TripCancellationDialog> {
  String? _selectedReason;

  Future<bool> _showDiscardConfirmation(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        backgroundColor: confirmContext.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        ),
        title: Text(
          'Discard cancellation?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: confirmContext.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'You have selected a cancellation reason. Are you sure you want to discard it?',
          style: TextStyle(
            color: confirmContext.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, false),
            child: Text(
              'Keep editing',
              style: TextStyle(
                color: confirmContext.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, true),
            child: Text(
              'Discard',
              style: TextStyle(
                color: confirmContext.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedReason == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardConfirmation(context);
        if (shouldDiscard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: AlertDialog(
        backgroundColor: context.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        ),
        title: Text(
          'Cancel ride?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a reason so the ride record stays accurate. Repeated cancellations may affect account standing.',
                style: TextStyle(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for cancellation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: context.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const ValueKey('cancellation-reason-dropdown'),
                initialValue: _selectedReason,
                dropdownColor: context.colorScheme.surface,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                decoration: InputDecoration(
                  hintText: 'Select a reason',
                  hintStyle: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: context.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EasyRideRadius.md),
                    borderSide: BorderSide(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EasyRideRadius.md),
                    borderSide: BorderSide(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EasyRideRadius.md),
                    borderSide: BorderSide(
                      color: context.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                items: TripCancellationDialog.cancellationReasons.entries
                    .map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_selectedReason != null) {
                final shouldDiscard = await _showDiscardConfirmation(context);
                if (shouldDiscard && context.mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Keep ride',
              style: TextStyle(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('confirm-cancel-ride-button'),
            onPressed: _selectedReason == null
                ? null
                : () => Navigator.pop(context, _selectedReason),
            child: Text(
              'Cancel ride',
              style: TextStyle(
                color: context.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

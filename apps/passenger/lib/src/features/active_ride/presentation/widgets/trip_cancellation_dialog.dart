import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class TripCancellationDialog extends StatefulWidget {
  const TripCancellationDialog({super.key});

  static const List<String> cancellationReasons = [
    'Driver is taking too long',
    'Driver asked to cancel',
    'Wrong pickup location',
    'Changed my mind',
    'Found another ride',
    'Other',
  ];

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
          Navigator.pop(context, false);
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
                'Are you sure you want to cancel this ride? A cancellation fee may apply.',
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
                items: TripCancellationDialog.cancellationReasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(
                      reason,
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
                  Navigator.pop(context, false);
                }
              } else {
                Navigator.pop(context, false);
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
            onPressed: () {
              Navigator.pop(context, true);
            },
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

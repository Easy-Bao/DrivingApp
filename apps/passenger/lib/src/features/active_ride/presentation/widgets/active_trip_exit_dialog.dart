import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum ActiveTripExitAction { keepTracking, minimize, cancel }

class const ActiveTripExitDialog({required this.driverName, super.key})
    extends StatelessWidget {
  final String driverName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
      ),
      title: Text(
        'Trip in progress',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: context.colorScheme.onSurface,
        ),
      ),
      content: Text(
        'You have an ongoing ride with $driverName.\n\nWhat would you like to do?',
        style: TextStyle(
          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ActiveTripExitAction.cancel),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, EasyRideSize.minimumTouchTarget),
          ),
          child: Text(
            'Cancel ride',
            style: TextStyle(
              color: context.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, ActiveTripExitAction.minimize),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, EasyRideSize.minimumTouchTarget),
          ),
          child: Text(
            'Go to home',
            style: TextStyle(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, ActiveTripExitAction.keepTracking),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, EasyRideSize.minimumTouchTarget),
          ),
          child: const Text('Keep tracking'),
        ),
      ],
    );
  }
}

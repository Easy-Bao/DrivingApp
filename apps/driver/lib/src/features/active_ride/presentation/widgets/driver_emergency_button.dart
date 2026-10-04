import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _emergencyContactNumber = '911';

class const DriverEmergencyButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => unawaited(showDriverEmergencyContacts(context)),
      tooltip: 'Call emergency services (911)',
      icon: const Icon(Icons.emergency_outlined),
      color: context.colorScheme.error,
      constraints: const BoxConstraints(
        minWidth: EasyRideSize.minimumTouchTarget,
        minHeight: EasyRideSize.minimumTouchTarget,
      ),
    );
  }
}

Future<void> showDriverEmergencyContacts(BuildContext context) async {
  final emergencyUri = Uri(scheme: 'tel', path: _emergencyContactNumber);
  var launched = false;
  try {
    launched =
        await canLaunchUrl(emergencyUri) && await launchUrl(emergencyUri);
  } catch (_) {
    launched = false;
  }
  if (launched || !context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Emergency contacts'),
      content: const Text(
        'Your device cannot open the phone dialer. Call emergency services at 911.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

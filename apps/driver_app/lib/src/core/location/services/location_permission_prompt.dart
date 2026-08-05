import 'package:driver_app/src/core/location/services/device_location_service.dart';
import 'package:flutter/material.dart';

class LocationPermissionPrompt {
  LocationPermissionPrompt._();

  static Future<bool> ensure(
    BuildContext context, {
    required String title,
    required String message,
    String secondaryLabel = 'Maybe Later',
  }) async {
    final accessState = await LocationService.getAccessState();
    if (accessState == LocationAccessState.ready) return true;
    if (!context.mounted) return false;

    final action = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined, size: 36),
        title: Text(
          accessState == LocationAccessState.serviceDisabled
              ? 'Turn on location services'
              : title,
        ),
        content: Text(
          accessState == LocationAccessState.serviceDisabled
              ? 'Location services are turned off. Enable them to keep receiving nearby ride requests.'
              : accessState == LocationAccessState.deniedForever
              ? 'Location access is disabled for this app. You can enable it in device settings when you are ready.'
              : message,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(secondaryLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              accessState == LocationAccessState.denied
                  ? 'Allow Location Access'
                  : 'Open Settings',
            ),
          ),
        ],
      ),
    );
    if (action != true || !context.mounted) return false;

    if (accessState == LocationAccessState.denied) {
      return LocationService.requestPermission();
    }
    if (accessState == LocationAccessState.serviceDisabled) {
      await LocationService.openLocationSettings();
    } else {
      await LocationService.openAppSettings();
    }
    return false;
  }
}

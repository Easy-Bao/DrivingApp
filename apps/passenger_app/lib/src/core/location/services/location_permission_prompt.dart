import 'package:flutter/material.dart';
import 'package:passenger_app/src/core/location/services/device_location_service.dart';

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

    final action = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
      builder: (sheetContext) => _LocationPermissionSheet(
        title: accessState == LocationAccessState.serviceDisabled
            ? 'Turn on location services'
            : title,
        message: accessState == LocationAccessState.serviceDisabled
            ? 'Location services are turned off. Enable them to calculate precise pickup points and nearby places.'
            : accessState == LocationAccessState.deniedForever
            ? 'Location access is disabled for this app. You can enable it in device settings when you are ready.'
            : message,
        primaryLabel: accessState == LocationAccessState.denied
            ? 'Allow Location Access'
            : 'Open Settings',
        secondaryLabel: secondaryLabel,
        onPrimaryPressed: () => Navigator.of(sheetContext).pop(true),
        onSecondaryPressed: () => Navigator.of(sheetContext).pop(false),
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

class _LocationPermissionSheet extends StatelessWidget {
  const _LocationPermissionSheet({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  Icons.location_on_outlined,
                  color: colorScheme.secondary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimaryPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
                child: Text(primaryLabel),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSecondaryPressed,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                ),
                child: Text(secondaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

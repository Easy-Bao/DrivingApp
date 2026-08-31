import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/src/theme/design_system_context.dart';

/// The small set of access states that the app-root location prompt renders.
enum LocationAccessOverlayState {
  checking,
  permissionDenied,
  serviceDisabled,
  permissionDeniedForever,
}

/// Keeps location recovery visible without replacing the route underneath it.
class LocationAccessOverlay extends StatelessWidget {
  const LocationAccessOverlay({
    super.key,
    required this.state,
    required this.appName,
    this.message,
    this.onOpenLocationSettings,
    this.onOpenAppSettings,
    this.onTryAgain,
  });

  final LocationAccessOverlayState state;
  final String appName;
  final String? message;
  final VoidCallback? onOpenLocationSettings;
  final VoidCallback? onOpenAppSettings;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '$appName location access',
      child: Stack(
        fit: StackFit.expand,
        children: [
          ModalBarrier(
            dismissible: false,
            color: colorScheme.scrim.withValues(alpha: 0.42),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.5,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1, end: 0),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                builder: (context, slideProgress, child) => LayoutBuilder(
                  builder: (context, constraints) => Transform.translate(
                    offset: Offset(0, constraints.maxHeight * slideProgress),
                    child: child,
                  ),
                ),
                child: _LocationAccessSheet(
                  state: state,
                  appName: appName,
                  message: message,
                  onOpenLocationSettings: onOpenLocationSettings,
                  onOpenAppSettings: onOpenAppSettings,
                  onTryAgain: onTryAgain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationAccessSheet extends StatelessWidget {
  const _LocationAccessSheet({
    required this.state,
    required this.appName,
    this.message,
    this.onOpenLocationSettings,
    this.onOpenAppSettings,
    this.onTryAgain,
  });

  final LocationAccessOverlayState state;
  final String appName;
  final String? message;
  final VoidCallback? onOpenLocationSettings;
  final VoidCallback? onOpenAppSettings;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final presentation = _presentation;
    final primaryAction = _primaryAction;
    return Material(
      key: const ValueKey<String>('location-access-overlay-sheet'),
      color: colorScheme.surface,
      elevation: 12,
      shadowColor: colorScheme.scrim.withValues(alpha: 0.28),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: presentation
                              .color(colorScheme)
                              .withValues(alpha: 0.13),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: state == LocationAccessOverlayState.checking
                            ? SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: presentation.color(colorScheme),
                                ),
                              )
                            : Icon(
                                presentation.icon,
                                size: 24,
                                color: presentation.color(colorScheme),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              presentation.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message ?? presentation.message,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (primaryAction != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: primaryAction.callback,
                        child: Text(primaryAction.label),
                      ),
                    ),
                  ],
                  if (onTryAgain != null &&
                      state != LocationAccessOverlayState.permissionDenied &&
                      state != LocationAccessOverlayState.checking) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: onTryAgain,
                        child: const Text('Try Again'),
                      ),
                    ),
                  ],
                  if (state == LocationAccessOverlayState.checking)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _LocationAccessPresentation get _presentation {
    return switch (state) {
      LocationAccessOverlayState.checking => _LocationAccessPresentation(
        icon: LucideIcons.loader_circle,
        title: 'Checking location access',
        message: '$appName is checking your phone settings and permission.',
        tone: _LocationAccessTone.neutral,
      ),
      LocationAccessOverlayState.permissionDenied =>
        _LocationAccessPresentation(
          icon: LucideIcons.map_pin,
          title: 'Location access needed',
          message: 'Allow location so $appName can keep pickups accurate.',
          tone: _LocationAccessTone.primary,
        ),
      LocationAccessOverlayState.serviceDisabled => _LocationAccessPresentation(
        icon: LucideIcons.map_pin_off,
        title: 'Location services are off',
        message:
            'Turn on your phone location service, then return to $appName.',
        tone: _LocationAccessTone.warning,
      ),
      LocationAccessOverlayState.permissionDeniedForever =>
        _LocationAccessPresentation(
          icon: LucideIcons.settings,
          title: 'Location permission is blocked',
          message: 'Allow location in app settings, then return to $appName.',
          tone: _LocationAccessTone.error,
        ),
    };
  }

  _LocationAccessAction? get _primaryAction {
    return switch (state) {
      LocationAccessOverlayState.checking => null,
      LocationAccessOverlayState.permissionDenied =>
        onTryAgain == null
            ? null
            : _LocationAccessAction(label: 'Try Again', callback: onTryAgain!),
      LocationAccessOverlayState.serviceDisabled =>
        onOpenLocationSettings == null
            ? null
            : _LocationAccessAction(
                label: 'Open Location Settings',
                callback: onOpenLocationSettings!,
              ),
      LocationAccessOverlayState.permissionDeniedForever =>
        onOpenAppSettings == null
            ? null
            : _LocationAccessAction(
                label: 'Open App Settings',
                callback: onOpenAppSettings!,
              ),
    };
  }
}

enum _LocationAccessTone { neutral, primary, warning, error }

class _LocationAccessPresentation {
  const _LocationAccessPresentation({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String message;
  final _LocationAccessTone tone;

  Color color(ColorScheme colorScheme) {
    return switch (tone) {
      _LocationAccessTone.neutral => colorScheme.onSurfaceVariant,
      _LocationAccessTone.primary => colorScheme.primary,
      _LocationAccessTone.warning => colorScheme.tertiary,
      _LocationAccessTone.error => colorScheme.error,
    };
  }
}

class _LocationAccessAction {
  const _LocationAccessAction({required this.label, required this.callback});

  final String label;
  final VoidCallback callback;
}

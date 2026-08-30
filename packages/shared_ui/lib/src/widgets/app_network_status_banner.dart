import 'package:flutter/material.dart';

/// Shows the quiet, app-wide transport status when the shared circuit opens.
///
/// This is intentionally a status surface without a retry action. Page loads
/// own their retry controls, while background work can report one shared state
/// without adding a second failure toast or page banner.
class AppNetworkStatusBanner extends StatelessWidget {
  const AppNetworkStatusBanner({super.key, required this.isVisible});

  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          child: Semantics(
            container: true,
            liveRegion: true,
            label: 'Connection unavailable. Retrying automatically.',
            child: Material(
              color: scheme.surfaceContainerHighest,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Connection unavailable. Retrying automatically.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

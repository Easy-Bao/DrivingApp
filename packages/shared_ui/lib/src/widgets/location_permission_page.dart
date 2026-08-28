import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class LocationPermissionPage extends StatelessWidget {
  const LocationPermissionPage({
    super.key,
    required this.onEnable,
    required this.onSkip,
    this.statusMessage,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      const Spacer(),
                      _LocationIllustration(colors: colors),
                      const SizedBox(height: 28),
                      Text(
                        'Make every pickup easier',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'EasyRide uses your location to find nearby drivers and place your pickup accurately.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                      if (statusMessage case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _LocationBenefit(
                        colors: colors,
                        icon: LucideIcons.car_front,
                        title: 'See nearby rides faster',
                        message:
                            'Get a clearer view of available drivers around you.',
                      ),
                      const SizedBox(height: 12),
                      _LocationBenefit(
                        colors: colors,
                        icon: LucideIcons.navigation,
                        title: 'Set the right pickup point',
                        message:
                            'Reduce missed pickups with a more accurate location.',
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onEnable,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text('Turn on location'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.onSurfaceVariant,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Not now'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationIllustration extends StatelessWidget {
  const _LocationIllustration({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.14),
          width: 14,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Icon(LucideIcons.map_pin, color: colors.primary, size: 34),
          ),
        ),
      ),
    );
  }
}

class _LocationBenefit extends StatelessWidget {
  const _LocationBenefit({
    required this.colors,
    required this.icon,
    required this.title,
    required this.message,
  });

  final ColorScheme colors;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

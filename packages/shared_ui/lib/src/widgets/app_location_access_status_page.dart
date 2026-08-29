import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/src/theme/easy_ride_theme_context.dart';

enum AppLocationAccessTone { neutral, success, warning, error }

class AppLocationAccessPresentation {
  const AppLocationAccessPresentation({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String message;
  final AppLocationAccessTone tone;
}

/// A state-agnostic location access page shared by both app roots.
class AppLocationAccessStatusPage extends StatelessWidget {
  const AppLocationAccessStatusPage({
    super.key,
    required this.presentation,
    required this.onBack,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onRetry,
    this.audience = 'pickups and active trip tracking',
  });

  final AppLocationAccessPresentation presentation;
  final VoidCallback onBack;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onRetry;
  final String audience;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          icon: const Icon(LucideIcons.arrow_left),
        ),
        title: const Text('Location access'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _toneColor(context).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        presentation.icon,
                        size: 30,
                        color: _toneColor(context),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      presentation.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      presentation.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (primaryActionLabel != null && onPrimaryAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onPrimaryAction,
                  child: Text(primaryActionLabel!),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              ],
              const SizedBox(height: 20),
              Text(
                'Why BaoRide needs location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const _LocationReason(
                icon: LucideIcons.map_pin,
                title: 'Accurate pickup points',
                message: 'Place pickups where passengers and drivers can meet.',
              ),
              const SizedBox(height: 10),
              _LocationReason(
                icon: LucideIcons.navigation,
                title: 'Live trip progress',
                message: 'Keep $audience useful and up to date.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _toneColor(BuildContext context) {
    return switch (presentation.tone) {
      AppLocationAccessTone.neutral => context.colorScheme.onSurfaceVariant,
      AppLocationAccessTone.success => context.semanticColors.success,
      AppLocationAccessTone.warning => context.semanticColors.warning,
      AppLocationAccessTone.error => context.colorScheme.error,
    };
  }
}

class _LocationReason extends StatelessWidget {
  const _LocationReason({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: context.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

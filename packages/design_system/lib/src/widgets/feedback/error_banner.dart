import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/widgets/feedback/network_status_scope.dart';

class const AppErrorBanner({
  super.key,
  required this.message,
  required this.onRetry,
  this.onDismiss,
}) extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return const SizedBox.shrink();
    }

    final scheme = context.colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circle_alert,
              size: 20,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: scheme.onErrorContainer,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Retry'),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: scheme.onErrorContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

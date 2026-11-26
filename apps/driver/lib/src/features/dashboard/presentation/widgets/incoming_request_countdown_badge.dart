import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

int? remainingCountdownSeconds(DateTime? expiry, DateTime now) {
  return expiry?.difference(now).inSeconds.clamp(0, 3599);
}

class const IncomingRequestCountdownBadge({
  super.key,
  required this.clock,
  required this.expiry,
}) extends StatelessWidget {
  final ValueListenable<DateTime> clock;
  final DateTime? expiry;

  @override
  Widget build(BuildContext context) {
    final expiry = this.expiry;
    if (expiry == null) return const SizedBox.shrink();

    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    return ValueListenableBuilder<DateTime>(
      valueListenable: clock,
      builder: (context, now, _) {
        final seconds = remainingCountdownSeconds(expiry, now) ?? 0;
        final isUrgent = seconds <= 10;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isUrgent
                  ? colorScheme.error.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.clock,
                  size: 13,
                  color: isUrgent
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${seconds}s',
                style: textStyles.labelSmall?.tabular.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUrgent ? colorScheme.error : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class const IncomingRequestCountdownLabel({
  super.key,
  required this.clock,
  required this.expiry,
}) extends StatelessWidget {
  final ValueListenable<DateTime> clock;
  final DateTime? expiry;

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.bodyMedium?.tabular.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    final expiry = this.expiry;
    if (expiry == null) {
      return Text('Review the trip before accepting.', style: style);
    }
    return ValueListenableBuilder<DateTime>(
      valueListenable: clock,
      builder: (context, now, _) {
        final seconds = remainingCountdownSeconds(expiry, now) ?? 0;
        return Text('Respond within $seconds seconds', style: style);
      },
    );
  }
}

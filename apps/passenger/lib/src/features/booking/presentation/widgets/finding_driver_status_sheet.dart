import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

/// Shared status surface for the driver-discovery states.
///
/// Keeping the status visual, trip context, and recovery action in one shell
/// makes the search feel like a focused transaction instead of three unrelated
/// pages. The individual panels still own their public callbacks and copy.
class FindingDriverStatusSheet extends StatelessWidget {
  const FindingDriverStatusSheet({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.statusIcon,
    required this.statusColor,
    required this.destination,
    required this.fare,
    required this.onCancelPressed,
    this.statusAnimation,
    this.primaryAction,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.isCanceling = false,
  });

  final String eyebrow;
  final String title;
  final String message;
  final IconData statusIcon;
  final Color statusColor;
  final String destination;
  final double fare;
  final VoidCallback onCancelPressed;
  final Animation<double>? statusAnimation;
  final VoidCallback? primaryAction;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final hasPrimaryAction =
        primaryAction != null && primaryActionLabel != null;

    return Material(
      key: const ValueKey<String>('finding-driver-status-sheet'),
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: colorScheme.onSurface.withValues(alpha: 0.14),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              _buildStatusVisual(),
              const SizedBox(height: 10),
              Text(
                eyebrow.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              _buildTitle(colorScheme),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              _buildTripContext(colorScheme),
              if (hasPrimaryAction) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: isCanceling ? null : primaryAction,
                    icon: Icon(primaryActionIcon, size: 18),
                    label: Text(primaryActionLabel!),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: isCanceling ? null : onCancelPressed,
                  child: isCanceling
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : const Text('Cancel search'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusVisual() {
    final iconTile = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Icon(statusIcon, color: statusColor, size: 27),
    );

    final animation = statusAnimation;
    if (animation == null) {
      return Center(child: iconTile);
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => SizedBox.square(
        dimension: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 72,
              child: CircularProgressIndicator(
                value: animation.value,
                strokeWidth: 2.5,
                color: statusColor.withValues(alpha: 0.38),
                backgroundColor: statusColor.withValues(alpha: 0.08),
              ),
            ),
            child!,
          ],
        ),
      ),
      child: iconTile,
    );
  }

  Widget _buildTitle(ColorScheme colorScheme) {
    final animation = statusAnimation;
    if (animation == null) {
      return Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final dots = '.' * (1 + (animation.value * 3).floor());
        return Text(
          '$title$dots',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        );
      },
    );
  }

  Widget _buildTripContext(ColorScheme colorScheme) {
    return Container(
      key: const ValueKey<String>('finding-driver-trip-context'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.map_pin,
              size: 18,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Going to',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Estimate',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatPesoAmount(fare),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

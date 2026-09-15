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
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(EasyRideRadius.sheet),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      shadowColor: colorScheme.onSurface.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(EasyRideRadius.pill),
                  ),
                ),
              ),
              _buildStatusVisual(),
              const SizedBox(height: 12),
              Text(
                eyebrow.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              _buildTitle(colorScheme),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTripContext(colorScheme),
              if (hasPrimaryAction) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: isCanceling ? null : primaryAction,
                    icon: Icon(primaryActionIcon, size: 18),
                    label: Text(
                      primaryActionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EasyRideRadius.md),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: isCanceling ? null : onCancelPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EasyRideRadius.md),
                    ),
                  ),
                  child: isCanceling
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurface,
                          ),
                        )
                      : const Text(
                          'Cancel search',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusVisual() {
    final animation = statusAnimation;
    final isScanning = animation != null;

    final iconBadge = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(statusIcon, color: statusColor, size: 26),
    );

    if (!isScanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: iconBadge,
        ),
      );
    }

    return Center(
      child: SizedBox.square(
        dimension: 88,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = animation.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer expanding radar pulse
                Transform.scale(
                  scale: 1.0 + (t * 0.36),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(
                          alpha: (1.0 - t).clamp(0.0, 1.0) * 0.4,
                        ),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                // Inner expanding radar pulse
                Transform.scale(
                  scale: 1.0 + (((t + 0.5) % 1.0) * 0.24),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(
                          alpha: (1.0 - ((t + 0.5) % 1.0)).clamp(0.0, 1.0) *
                              0.3,
                        ),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            );
          },
          child: iconBadge,
        ),
      ),
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
          fontSize: 20,
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
            fontSize: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.map_pin,
              size: 18,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOING TO',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
                    fontWeight: FontWeight.w700,
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
                'ESTIMATE',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatPesoAmount(fare),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

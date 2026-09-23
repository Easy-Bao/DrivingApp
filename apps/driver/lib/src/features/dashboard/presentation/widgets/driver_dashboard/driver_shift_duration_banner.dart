import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const DriverShiftDurationBanner({super.key, required this.duration})
    extends StatelessWidget {
  static const breakThreshold = Duration(hours: 8);

  final Duration duration;

  bool get breakRecommended => duration >= breakThreshold;

  @override
  Widget build(BuildContext context) {
    final color = breakRecommended
        ? context.colorScheme.error
        : context.colorScheme.primary;
    return Container(
      key: const ValueKey<String>('driver-shift-duration-banner'),
      margin: const EdgeInsets.symmetric(
        horizontal: EasyRideLayout.pagePadding,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock_3, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online for ${formatDuration(duration)}',
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (breakRecommended)
                  Text(
                    'Take a break before continuing.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

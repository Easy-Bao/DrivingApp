import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

class const RecentRideHistoryPreview({
  required this.rides,
  required this.onRideTap,
  super.key,
}) extends StatelessWidget {
  final List<RideHistory> rides;
  final ValueChanged<RideHistory> onRideTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: rides.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 54,
        color: colors.outlineVariant.withValues(alpha: 0.7),
      ),
      itemBuilder: (context, index) {
        final ride = rides[index];
        final pickup = ride.pickup.trim();
        final subtitle = pickup.isEmpty ? ride.displayDriverName : pickup;

        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => onRideTap(ride),
            borderRadius: BorderRadius.circular(AppRadius.md),
            enableFeedback: false,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? colors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.map_pin,
                      color: colors.onSurface,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.destination.isEmpty
                              ? 'Destination unavailable'
                              : ride.destination,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.chevron_right,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:passenger_app/src/features/activity/activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/design_system.dart';

class RecentRideHistoryPreviewWidget extends StatelessWidget {
  const RecentRideHistoryPreviewWidget({
    required this.rides,
    required this.onRideTap,
    super.key,
  });

  final List<RideHistory> rides;
  final ValueChanged<RideHistory> onRideTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: rides.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: context.colorScheme.outlineVariant),
      itemBuilder: (context, index) {
        final ride = rides[index];
        final pickup = ride.pickup.trim();
        final subtitle = pickup.isEmpty ? ride.displayDriverName : pickup;

        return InkWell(
          onTap: () => onRideTap(ride),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.map_pin,
                    color: context.colorScheme.onSurface,
                    size: 20,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevron_right,
                  size: 16,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

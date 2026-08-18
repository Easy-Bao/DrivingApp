import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:shared_core/shared_core.dart';

class RecentRideHistoryPreviewWidget extends StatelessWidget {
  const RecentRideHistoryPreviewWidget({
    required this.rides,
    required this.onRideTap,
    super.key,
  });

  final List<RideHistoryModel> rides;
  final ValueChanged<RideHistoryModel> onRideTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: rides.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppTheme.borderSide),
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
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.map_pin,
                    color: AppTheme.primaryColor,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevron_right,
                  size: 16,
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

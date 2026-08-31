import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class FindingDriverNearestPanelWidget extends StatelessWidget {
  final NearestDriverFound state;
  final double fare;
  final VoidCallback onViewFullProfilePressed;
  final VoidCallback onBookDirectPressed;
  final VoidCallback onSearchAllDriversPressed;
  final VoidCallback onCancelRidePressed;
  final bool isCanceling;

  const FindingDriverNearestPanelWidget({
    super.key,
    required this.state,
    required this.fare,
    required this.onViewFullProfilePressed,
    required this.onBookDirectPressed,
    required this.onSearchAllDriversPressed,
    required this.onCancelRidePressed,
    this.isCanceling = false,
  });

  @override
  Widget build(BuildContext context) {
    final driver = state.driver;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.user_round,
                  color: context.colorScheme.onSurface,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearest Driver',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      driver.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      driver.vehicleSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPesoAmount(fare),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Estimated Fare',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                context,
                icon: Icons.star_rounded,
                label: '${driver.rating.toStringAsFixed(1)} Rating',
                color: context.semanticColors.warning,
              ),
              const SizedBox(width: 8),
              _metric(
                context,
                icon: LucideIcons.navigation,
                label:
                    '${DistanceFormatter.fromKilometers(driver.distanceKm)} Away',
              ),
              const SizedBox(width: 8),
              _metric(
                context,
                icon: driver.hasPassengerOnboard
                    ? LucideIcons.users
                    : LucideIcons.user_check,
                label: driver.hasPassengerOnboard ? 'On Trip' : 'Available',
                color: driver.hasPassengerOnboard
                    ? context.semanticColors.warning
                    : context.semanticColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewFullProfilePressed,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Profile'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onBookDirectPressed,
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Choose Driver'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onSearchAllDriversPressed,
                  child: const Text('Compare All Drivers'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: isCanceling ? null : onCancelRidePressed,
                  child: isCanceling
                      ? SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colorScheme.error,
                          ),
                        )
                      : Text(
                          'Cancel Ride',
                          style: TextStyle(color: context.colorScheme.error),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final resolvedColor = color ?? context.colorScheme.onSurface;
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: resolvedColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:shared_core/shared_core.dart';

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
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
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
              color: AppTheme.borderSide,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.neutralColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.user_round,
                  color: AppTheme.primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearest Driver',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tertiaryColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      driver.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      driver.vehicleSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.tertiaryColor,
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
                    '₱${fare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Text(
                    'Estimated Fare',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.tertiaryColor,
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
                icon: Icons.star_rounded,
                label: '${driver.rating.toStringAsFixed(1)} Rating',
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              _metric(
                icon: LucideIcons.navigation,
                label:
                    '${DistanceFormatter.fromKilometers(driver.distanceKm)} Away',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: driver.hasPassengerOnboard
                    ? LucideIcons.users
                    : LucideIcons.user_check,
                label: driver.hasPassengerOnboard ? 'On Trip' : 'Available',
                color: driver.hasPassengerOnboard
                    ? AppTheme.warning
                    : AppTheme.complete,
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
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.cancel,
                          ),
                        )
                      : const Text(
                          'Cancel Ride',
                          style: TextStyle(color: AppTheme.cancel),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    Color color = AppTheme.primaryColor,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

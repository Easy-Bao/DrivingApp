import 'dart:async';

import 'package:driver_app/src/core/di/service_locator.dart';
import 'package:driver_services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

/// Ride Alert Screen component defining application state or layout.
class RideAlertScreen extends StatefulWidget {
  final Map<String, dynamic>? rideData;
  const RideAlertScreen({super.key, this.rideData});

  @override
  State<RideAlertScreen> createState() => _RideAlertScreenState();
}

class _RideAlertScreenState extends State<RideAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;
  Timer? _autoDecline;

  late final String _rideId;
  late final String _pickup;
  late final String _dropoff;
  late final double _distance;
  late final double _fare;
  late final String _duration;

  @override
  void initState() {
    super.initState();

    _rideId = widget.rideData?['id'] as String? ?? 'mock_id';
    _pickup =
        widget.rideData?['pickup_name'] as String? ??
        'SM City Dipolog, Rizal Ave';
    _dropoff =
        widget.rideData?['dropoff_name'] as String? ??
        'Dipolog Public Market, Quezon St';
    _distance = (widget.rideData?['distance'] ?? 3.2) as double;
    _fare = (widget.rideData?['fare'] ?? 52.00) as double;
    _duration = widget.rideData?['duration'] as String? ?? '8 min';

    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();
    _autoDecline = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        CustomToast.show(context, 'Ride request expired', isError: true);
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _autoDecline?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    _autoDecline?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id') ?? '';
    final driverName = prefs.getString('driver_name') ?? 'Driver';
    final vehicleType = prefs.getString('vehicle_type') ?? 'Bao Bao';
    final plateNumber = prefs.getString('plate_number') ?? 'ABC 1234';

    final success = await getIt<BiddingApiService>().placeBid(
      sessionId: _rideId,
      driverId: driverId,
      driverName: driverName,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      proposedFare: _fare,
    );

    if (mounted) {
      if (success) {
        CustomToast.show(context, 'Offer submitted! Waiting for passenger...');
      } else {
        CustomToast.show(context, 'Failed to submit offer.', isError: true);
      }
      context.pop();
    }
  }

  void _decline() {
    _autoDecline?.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NEW RIDE REQUEST',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.tertiaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₱${_fare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _timerCtrl,
                builder: (ctx, _) {
                  final remaining = 15 - (_timerCtrl.value * 15).floor();
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1.0 - _timerCtrl.value,
                          minHeight: 6,
                          backgroundColor: AppTheme.borderSide,
                          valueColor: AlwaysStoppedAnimation(
                            remaining <= 5
                                ? AppTheme.cancel
                                : AppTheme.complete,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${remaining}s remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: remaining <= 5
                              ? AppTheme.cancel
                              : AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderSide),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: AppTheme.outlineBorderColor,
                            ),
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppTheme.tertiaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _pickup,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Drop off',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dropoff,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _infoBox(
                      LucideIcons.map_pin,
                      '$_distance km',
                      'Distance',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoBox(LucideIcons.clock, _duration, 'ETA'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoBox(LucideIcons.banknote, 'Cash', 'Payment'),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _accept,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.complete,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.complete.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Accept Ride',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _decline,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.cancel.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.cancel,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.tertiaryColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

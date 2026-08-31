import 'package:passenger_app/src/features/activity/activity.dart';
import 'dart:async';
import 'package:maps/maps.dart';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:passenger_app/src/features/driver_profile/presentation/driver_profile_details_sheet.dart';
import 'package:shared_core/shared_core.dart';
import 'package:design_system/design_system.dart';

class DriverMatchedPage extends StatefulWidget {
  final String rideType;
  final double fare;
  final Place destination;
  final String distance;
  final String duration;
  final String? driverId;
  final String? driverName;
  final String? driverRating;
  final String? vehicleType;
  final String? plateNumber;
  final String? pickupAddress;
  final RideHistory? createdRide;
  final IDriverProfileRepository profileRepository;

  const DriverMatchedPage({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.driverId,
    this.driverName,
    this.driverRating,
    this.vehicleType,
    this.plateNumber,
    this.pickupAddress,
    this.createdRide,
    required this.profileRepository,
  });

  @override
  State<DriverMatchedPage> createState() => _DriverMatchedPageState();
}

class _DriverMatchedPageState extends State<DriverMatchedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  Timer? _autoNav;
  RideHistory? _createdRide;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    unawaited(_scaleCtrl.forward());
    unawaited(_saveRideAndStartTimer());
  }

  Future<void> _saveRideAndStartTimer() async {
    final ride = widget.createdRide;
    if (ride == null || ride.id.isEmpty) return;
    if (mounted) {
      setState(() => _createdRide = ride);
      _autoNav = Timer(const Duration(seconds: 1), _goToTracking);
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _autoNav?.cancel();
    super.dispose();
  }

  void _goToTracking() {
    if (!mounted) return;
    final ride = _createdRide;
    if (ride == null || ride.id.isEmpty) return;
    context.goNamed(ActiveRideRoutes.trackDriver, extra: ride);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: context.semanticColors.success.withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.semanticColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.semanticColors.success.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.check,
                        color: context.colorScheme.surface,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Driver Found!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${widget.rideType} driver is on the way',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),

              GestureDetector(
                onTap: () {
                  unawaited(
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: context.colorScheme.surface.withValues(
                        alpha: 0,
                      ),
                      builder: (BuildContext sheetContext) =>
                          DriverProfileDetailsSheet(
                            driverId: widget.driverId ?? '',
                            driverName: widget.driverName ?? '—',
                            vehicleType: widget.vehicleType ?? '—',
                            plateNumber: widget.plateNumber ?? '—',
                            rating: widget.driverRating ?? '—',
                            repository: widget.profileRepository,
                          ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: context.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              LucideIcons.user,
                              color: context.colorScheme.onSurface,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.driverName ?? '—',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: context.semanticColors.rating,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.driverRating ?? '—',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: context.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '  •  Server match',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: context.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _infoChip(
                            LucideIcons.bike,
                            widget.vehicleType ?? '—',
                          ),
                          _infoChip(
                            LucideIcons.hash,
                            widget.plateNumber ?? '—',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.destination.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatPesoAmount(widget.fare),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _goToTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.onSurface,
                    foregroundColor: context.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Track Your Driver',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Opening live tracking…',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

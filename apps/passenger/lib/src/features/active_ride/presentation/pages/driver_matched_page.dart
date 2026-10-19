import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/driver_profile/presentation/widgets/driver_profile_details_sheet.dart';

class const DriverMatchedPage({
  super.key,
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
  this.pickupLatitude,
  this.pickupLongitude,
  this.rideId,
  required this.profileRepository,
}) extends StatefulWidget {
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
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? rideId;
  final DriverProfileRepository profileRepository;

  @override
  State<DriverMatchedPage> createState() => _DriverMatchedPageState();
}

class _DriverMatchedPageState extends State<DriverMatchedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;
  Timer? _countdownTimer;
  int _secondsLeft = 4;

  String? get _rideId => widget.rideId?.trim();

  @override
  void initState() {
    super.initState();
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    );
    unawaited(_scaleAnimationController.forward());
    if (_rideId?.isNotEmpty == true) _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _goToTracking();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _pauseCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _goToTracking() {
    if (!mounted) return;
    final rideId = _rideId;
    if (rideId == null || rideId.isEmpty) return;

    final pickupName = widget.pickupAddress?.trim();
    context.goNamed(
      ActiveRideRoutes.trackDriver,
      extra: {
        'id': rideId,
        'status': 'accepted',
        'pickup_name': pickupName == null || pickupName.isEmpty
            ? 'Current Location'
            : pickupName,
        'dropoff_name': widget.destination.name,
        'driver_id': widget.driverId ?? '',
        'driver_name': widget.driverName ?? '',
        'vehicle_type': widget.vehicleType ?? '',
        'plate_number': widget.plateNumber ?? '',
        'driver_rating': widget.driverRating,
        'pickup_latitude': widget.pickupLatitude,
        'pickup_longitude': widget.pickupLongitude,
        'dropoff_latitude': widget.destination.latitude,
        'dropoff_longitude': widget.destination.longitude,
        'fare_amount': (widget.fare * 100).round(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600
                ? EasyRideLayout.pagePaddingWide
                : EasyRideLayout.pagePadding;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
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
                        'Your driver is on the way',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Semantics(
                        button: true,
                        label: 'View driver details',
                        hint: 'Opens the driver profile',
                        child: GestureDetector(
                          onTap: () async {
                            _pauseCountdown();
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: context.colorScheme.surface
                                  .withValues(alpha: 0),
                              builder: (BuildContext sheetContext) =>
                                  DriverProfileDetailsSheet(
                                    driverId: widget.driverId ?? '',
                                    driverName: widget.driverName ?? '—',
                                    vehicleType: widget.vehicleType ?? '—',
                                    plateNumber: widget.plateNumber ?? '—',
                                    rating: widget.driverRating ?? '—',
                                    repository: widget.profileRepository,
                                  ),
                            );
                            if (mounted && _rideId?.isNotEmpty == true) {
                              _startCountdown();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(EasyRideSpacing.lg),
                            decoration: BoxDecoration(
                              color:
                                  context.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                EasyRideRadius.lg,
                              ),
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
                                        color: context.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.user,
                                        color: context.colorScheme.onPrimary,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.driverName ?? '—',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  context.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                size: 16,
                                                color: context
                                                    .semanticColors
                                                    .rating,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                widget.driverRating ?? '—',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: context
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  '  •  Server match',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: context
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
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
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            EasyRideRadius.lg,
                          ),
                          border: Border.all(
                            color: context.colorScheme.outlineVariant,
                          ),
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
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: EasyRideSize.controlHeight,
                        child: ElevatedButton(
                          onPressed: _goToTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: context.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                EasyRideRadius.lg,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Track Your Driver',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _rideId?.isNotEmpty == true
                            ? 'Opening live tracking in ${_secondsLeft}s…'
                            : 'Tap above to open live tracking',
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
          },
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.md),
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

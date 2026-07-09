/// Driver Matched Screen: shows driver profiles and trip summaries when passenger bookings are confirmed.
library;

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:passenger_app/shared/widgets/driver_profile_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverMatchedScreen extends StatefulWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? driverId;
  final String? driverName;
  final String? driverRating;
  final String? vehicleType;
  final String? plateNumber;
  final String? pickupAddress;

  const DriverMatchedScreen({
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
  });

  @override
  State<DriverMatchedScreen> createState() => _DriverMatchedScreenState();
}

class _DriverMatchedScreenState extends State<DriverMatchedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  Timer? _autoNav;
  RideHistoryModel? _createdRide;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      var activeRideId = prefs.getString('active_ride_id') ?? '';
      var pickupLat = LocationService.lastPosition?.latitude ?? widget.destination.latitude;
      var pickupLng = LocationService.lastPosition?.longitude ?? widget.destination.longitude;
      var pickupName = widget.pickupAddress ?? 'Current Location';
      var driverName = widget.driverName ?? 'Driver';
      var vehiclePlate = widget.plateNumber ?? 'ABC 1234';

      if (activeRideId.isEmpty) {
        final passengerId = prefs.getString('passenger_id') ?? '';
        if (passengerId.isNotEmpty) {
          final res = await PassengerApiService.createRideRequest(
            passengerId: passengerId,
            rideType: widget.rideType,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            pickupName: pickupName,
            dropoffLat: widget.destination.latitude,
            dropoffLng: widget.destination.longitude,
            dropoffName: widget.destination.name,
            fare: widget.fare,
          );
          if (res != null && res['id'] != null) {
            activeRideId = res['id'] as String;
            await prefs.setString('active_ride_id', activeRideId);

            pickupLat = SafeParse.toDouble(res['pickup_latitude']);
            pickupLng = SafeParse.toDouble(res['pickup_longitude']);
            pickupName = res['pickup_name'] as String? ?? pickupName;
            driverName = res['driver_name'] as String? ?? driverName;
            vehiclePlate = res['plate_number'] as String? ?? vehiclePlate;
          }
        }
      } else {
        final res = await PassengerApiService.getRideStatus(activeRideId);
        if (res != null) {
          pickupLat = SafeParse.toDouble(res['pickup_latitude']);
          pickupLng = SafeParse.toDouble(res['pickup_longitude']);
          pickupName = res['pickup_name'] as String? ?? pickupName;
          driverName = res['driver_name'] as String? ?? driverName;
          vehiclePlate = res['plate_number'] as String? ?? vehiclePlate;
        }
      }

      if (mounted) {
        setState(() {
          _createdRide = RideHistoryModel(
            id: activeRideId,
            pickup: pickupName,
            destination: widget.destination.name,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            destLat: widget.destination.latitude,
            destLng: widget.destination.longitude,
            date: DateTime.now().toLocal().toString(),
            price: '₱${widget.fare.toStringAsFixed(2)}',
            status: 'accepted',
            driverName: driverName,
            vehiclePlate: vehiclePlate,
          );
        });
      }
    } catch (error) {
      debugPrint('Error creating ride request in DB: $error');
    }
    if (mounted) {
      _autoNav = Timer(const Duration(seconds: 4), _goToTracking);
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
    final ride = _createdRide ??
        RideHistoryModel(
          id: '',
          pickup: widget.pickupAddress ?? 'Current Location',
          destination: widget.destination.name,
          pickupLat: LocationService.lastPosition?.latitude ?? widget.destination.latitude,
          pickupLng: LocationService.lastPosition?.longitude ?? widget.destination.longitude,
          destLat: widget.destination.latitude,
          destLng: widget.destination.longitude,
          date: DateTime.now().toLocal().toString(),
          price: '₱${widget.fare.toStringAsFixed(2)}',
          status: 'accepted',
          driverName: widget.driverName ?? 'Driver',
          vehiclePlate: widget.plateNumber ?? 'ABC 1234',
        );
    context.goNamed('ActivityTrackDriver', extra: ride);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
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
                    color: AppTheme.complete.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.complete,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.complete.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Driver Found!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${widget.rideType} driver is on the way',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 36),

              GestureDetector(
                onTap: () {
                  unawaited(
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext sheetContext) => DriverProfileDetailsSheet(
                        driverId: widget.driverId ?? 'driver-id-xyz',
                        driverName: widget.driverName ?? 'Driver',
                        vehicleType: widget.vehicleType ?? 'Bao Bao',
                        plateNumber: widget.plateNumber ?? 'ABC 1234',
                        rating: widget.driverRating ?? '5.0',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderSide),
                  ),
                  child: Column(
                    children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            color: AppTheme.primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.driverName ?? 'Xyrel D. Tenefrancia',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Color(0xFFDAA520),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.driverRating ?? '4.9',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    '  •  Local Match',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.5,
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
                    const Divider(height: 1, color: AppTheme.borderSide),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _infoChip(
                          LucideIcons.bike,
                          widget.vehicleType ?? 'Bao Bao',
                        ),
                        _infoChip(
                          LucideIcons.hash,
                          widget.plateNumber ?? 'ABC 1234',
                        ),
                        _infoChip(LucideIcons.palette, 'Black'),
                      ],
                    ),
                  ],
                ),
              ),),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderSide),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: AppTheme.tertiaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.destination.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₱${widget.fare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
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
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
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
                'Auto-redirecting in a moment...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.tertiaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:driver_app/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_cubit.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_state.dart';
import 'package:location_service/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/shared/widgets/custom_toast.dart';
import 'package:driver_app/core/services/driver_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Driver has arrived at pickup and is waiting for the passenger to board.
class WaitingPassengerScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const WaitingPassengerScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<WaitingPassengerScreen> createState() => _WaitingPassengerScreenState();
}

class _WaitingPassengerScreenState extends State<WaitingPassengerScreen> {
  int _waitSeconds = 0;
  Timer? _waitTimer;

  @override
  void initState() {
    super.initState();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _waitSeconds++);
    });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  String get _waitFormatted {
    final m = _waitSeconds ~/ 60;
    final s = _waitSeconds % 60;
    return '${minuteseconds.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static const double _defaultLat = 7.8286;
  static const double _defaultLng = 123.4361;

  Future<void> _startTrip() async {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowWaitingPassenger
        ? state.passengerName
        : 'Passenger';

    final pickupLat = LocationService.lastPosition?.latitude ?? _defaultLat;
    final pickupLng = LocationService.lastPosition?.longitude ?? _defaultLng;

    double destLat = pickupLat + 0.03;
    double destLng = pickupLng + 0.03;

    try {
      final places = await MapProvider.searchPlaces(widget.dropoff);
      if (places.isNotEmpty) {
        destLat = places.first.latitude;
        destLng = places.first.longitude;
      }
    } catch (_) {}

    if (!mounted) return;

    await BlocProvider.of<RideFlowCubit>(context).startRide(
      passengerName: passengerName,
      destLat: destLat,
      destLng: destLng,
      distanceKm: widget.distance,
    );

    if (mounted) {
      context.pushReplacementNamed(
        'InTransit',
        extra: {
          'pickup': widget.pickup,
          'dropoff': widget.dropoff,
          'distance': widget.distance,
          'fare': widget.fare,
          'duration': widget.duration,
        },
      );
    }
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
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderSide),
                      ),
                      child: const Icon(
                        LucideIcons.arrow_left,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(),
                  const Spacer(),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
              const SizedBox(height: 32),
              _buildTimer(),
              const SizedBox(height: 32),
              _buildPassengerCard(),
              const SizedBox(height: 16),
              _buildActionRow(),
              const Spacer(),
              if (_waitSeconds >= 300) _buildNoShowButton(),
              _buildStartTripButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.map_pin_check,
            size: 15,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 8),
          Text(
            "You've Arrived",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          _waitFormatted,
          style: const TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Waiting for passenger',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerCard() {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowWaitingPassenger
        ? state.passengerName
        : 'Passenger';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Text(
                      'Passenger  •  ★ 4.7',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.tertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 15,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.pickup,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _btn(
            LucideIcons.phone,
            'Call',
            AppTheme.primaryColor,
            Colors.white,
            onTap: () async {
              try {
                final rideId =
                    BlocProvider.of<RideFlowCubit>(context).activeRideId ?? '';
                if (rideId.isNotEmpty) {
                  final ride = await DriverApiService.getRideStatus(rideId);
                  final passengerId = ride?['passenger_id'] as String?;
                  if (passengerId != null && passengerId.isNotEmpty) {
                    final passenger =
                        await DriverApiService.fetchPassengerProfile(passengerId);
                    final phone = passenger?['phone'] as String?;
                    if (phone != null && phone.isNotEmpty) {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  }
                }
              } catch (_) {}
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _btn(
            LucideIcons.message_circle,
            'Chat',
            AppTheme.neutralColor,
            AppTheme.primaryColor,
            onTap: () async {
              final rideId =
                  BlocProvider.of<RideFlowCubit>(context).activeRideId ?? '';
              final state = BlocProvider.of<RideFlowCubit>(context).state;
              final passengerName = state is RideFlowWaitingPassenger
                  ? state.passengerName
                  : 'Passenger';
              final prefs = await SharedPreferences.getInstance();
              final driverId = prefs.getString('driver_id') ?? '';
              if (mounted) {
                context.pushNamed(
                  'DriverChat',
                  extra: {
                    'roomId': rideId,
                    'userId': driverId,
                    'peerName': passengerName,
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoShowButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          CustomToast.show(
            context,
            'Ride canceled — no show',
            isError: true,
          );
          context.pop();
        },
        child: Text(
          'Cancel (Passenger no-show)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.cancel,
          ),
        ),
      ),
    );
  }

  Widget _buildStartTripButton() {
    return GestureDetector(
      onTap: _startTrip,
      child: Container(
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.play, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'START TRIP',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(
    IconData icon,
    String label,
    Color bg,
    Color fg, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(23),
          border: bg == AppTheme.neutralColor
              ? Border.all(color: AppTheme.borderSide)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

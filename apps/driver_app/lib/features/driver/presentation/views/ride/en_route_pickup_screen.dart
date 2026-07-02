import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_models/core_models.dart';
import 'package:driver_app/core/themes/app_themes.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_cubit.dart';
import 'package:location_service/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Driver is navigating to the passenger's pickup location.
class EnRoutePickupScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;

  const EnRoutePickupScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<EnRoutePickupScreen> createState() => _EnRoutePickupScreenState();
}

class _EnRoutePickupScreenState extends State<EnRoutePickupScreen> {
  double _sliderVal = 0;
  AppMapController? _mapController;
  bool _isLoading = true;
  RouteModel? _route;
  double _passengerLat = 8.5891;
  double _passengerLng = 123.3441;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final pos = await LocationService.getCurrentPosition() ?? LocationService.lastPosition;
    final dLat = pos?.latitude ?? 8.5879;
    final dLng = pos?.longitude ?? 123.3402;

    // Dynamically search passenger's coordinates
    final places = await MapProvider.searchPlaces(widget.pickup);
    if (places.isNotEmpty) {
      _passengerLat = places.first.latitude;
      _passengerLng = places.first.longitude;
    } else {
      if (widget.pickup.contains('SM City Dipolog')) {
        _passengerLat = 8.5891;
        _passengerLng = 123.3441;
      } else if (widget.pickup.contains('Dipolog Public Market')) {
        _passengerLat = 8.5862;
        _passengerLng = 123.3392;
      }
    }

    final route = await MapProvider.getRoute(
      dLat,
      dLng,
      _passengerLat,
      _passengerLng,
    );

    if (!mounted) return;
    setState(() {
      _route = route;
      _isLoading = false;
    });

    if (_mapController != null) {
      await _drawMapElements(dLat, dLng);
    }
  }

  Future<void> _drawMapElements(double dLat, double dLng) async {
    if (_mapController == null) return;

    // Driver marker
    await MapProvider.addMarker(
      _mapController!,
      dLat,
      dLng,
      isOrigin: true,
      label: 'Driver',
    );

    // Passenger marker
    await MapProvider.addMarker(
      _mapController!,
      _passengerLat,
      _passengerLng,
      label: 'Passenger',
    );

    // Fit bounds to show both driver and passenger
    await MapProvider.fitBounds(_mapController!, [
      LatLng(dLat, dLng),
      LatLng(_passengerLat, _passengerLng),
    ]);

    // Draw route polyline
    if (_route != null && _route!.polylinePoints.isNotEmpty) {
      await MapProvider.addPolyline(
        _mapController!,
        _route!.polylinePoints,
        color: AppTheme.primaryColor,
        width: 5.0,
      );
    }
  }

  void _confirmArrival() {
    BlocProvider.of<RideFlowCubit>(context).arriveAtPickup('Juan D. Cruz');
    context.pushReplacementNamed(
      'WaitingPassenger',
      extra: {
        'pickup': widget.pickup,
        'dropoff': widget.dropoff,
        'distance': widget.distance,
        'fare': widget.fare,
        'duration': widget.duration,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapProvider.buildMapView(
              latitude: LocationService.lastPosition?.latitude ?? 8.5879,
              longitude: LocationService.lastPosition?.longitude ?? 123.3402,
              zoom: 15.0,
              onMapCreated: (c) {
                _mapController = c;
                if (!_isLoading) {
                  final pos = LocationService.lastPosition;
                  final dLat = pos?.latitude ?? 8.5879;
                  final dLng = pos?.longitude ?? 123.3402;
                  _drawMapElements(dLat, dLng);
                }
              },
            ),
          ),
          SafeArea(child: _buildHeader()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(top: 20, bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRouteCard(),
                  const SizedBox(height: 16),
                  _buildInfoRow(),
                  const SizedBox(height: 16),
                  _buildPassengerCard(),
                  const SizedBox(height: 16),
                  _buildActionRow(),
                  const SizedBox(height: 20),
                  _buildSlider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
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
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.complete.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.navigation,
                  size: 13,
                  color: AppTheme.complete,
                ),
                const SizedBox(width: 6),
                Text(
                  'EN ROUTE TO PICKUP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.complete,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          children: [
            _routeRow(
              LucideIcons.circle_dot,
              'Pickup',
              widget.pickup,
              AppTheme.primaryColor,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
              child: Row(
                children: [
                  Container(width: 1, height: 16, color: AppTheme.borderSide),
                ],
              ),
            ),
            _routeRow(
              LucideIcons.map_pin,
              'Drop-off',
              widget.dropoff,
              AppTheme.tertiaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _infoChip(LucideIcons.map_pin, '${widget.distance} km'),
          const SizedBox(width: 8),
          _infoChip(LucideIcons.clock, widget.duration),
          const SizedBox(width: 8),
          _infoChip(LucideIcons.banknote, '₱${widget.fare.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppTheme.tertiaryColor),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Juan D. Cruz',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
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
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              LucideIcons.phone,
              'Call',
              AppTheme.primaryColor,
              Colors.white,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn(
              LucideIcons.message_circle,
              'Chat',
              AppTheme.neutralColor,
              AppTheme.primaryColor,
              onTap: () async {
                final rideId = BlocProvider.of<RideFlowCubit>(context).activeRideId ?? '';
                final prefs = await SharedPreferences.getInstance();
                final driverId = prefs.getString('driver_id') ?? '';
                if (mounted) {
                  context.pushNamed(
                    'DriverChat',
                    extra: {
                      'roomId': rideId,
                      'userId': driverId,
                      'peerName': 'Juan D. Cruz',
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color bg, Color fg, {required VoidCallback onTap}) {
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

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final maxW = constraints.maxWidth;
          return Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.complete.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    _sliderVal > 0.8
                        ? 'Release to confirm'
                        : 'Slide to confirm arrival',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.complete.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  left: _sliderVal * (maxW - 64),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(
                      () => _sliderVal = (_sliderVal + d.delta.dx / (maxW - 64))
                          .clamp(0.0, 1.0),
                    ),
                    onHorizontalDragEnd: (_) {
                      if (_sliderVal > 0.85) {
                        _confirmArrival();
                      } else {
                        setState(() => _sliderVal = 0);
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.complete,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.complete.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.chevron_right,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

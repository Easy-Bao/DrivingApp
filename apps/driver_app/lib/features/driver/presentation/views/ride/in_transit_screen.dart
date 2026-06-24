import 'package:driver_app/core/models/place/place_model.dart';
import 'package:driver_app/core/models/route/route_model.dart';
import 'package:driver_app/core/themes/app_themes.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_cubit.dart';
import 'package:driver_app/core/services/location_service.dart';
import 'package:driver_app/core/services/map_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Driver is actively transporting the passenger to their destination.
class InTransitScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const InTransitScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen> {
  AppMapController? _mapController;
  bool _isLoading = true;
  RouteModel? _route;
  double _destLat = 8.5862;
  double _destLng = 123.3392;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final pos = await LocationService.getCurrentPosition() ?? LocationService.lastPosition;
    final dLat = pos?.latitude ?? 8.5879;
    final dLng = pos?.longitude ?? 123.3402;

    // Dynamically search destination coordinates
    final places = await MapProvider.searchPlaces(widget.dropoff);
    if (places.isNotEmpty) {
      _destLat = places.first.latitude;
      _destLng = places.first.longitude;
    } else {
      if (widget.dropoff.contains('Dipolog Public Market')) {
        _destLat = 8.5862;
        _destLng = 123.3392;
      } else if (widget.dropoff.contains('SM City Dipolog')) {
        _destLat = 8.5891;
        _destLng = 123.3441;
      }
    }

    final route = await MapProvider.getRoute(
      dLat,
      dLng,
      _destLat,
      _destLng,
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

    // Driver/pickup marker
    await MapProvider.addMarker(
      _mapController!,
      dLat,
      dLng,
      isOrigin: true,
      label: 'Driver',
    );

    // Destination marker
    await MapProvider.addMarker(
      _mapController!,
      _destLat,
      _destLng,
      label: 'Destination',
    );

    // Fit bounds to show both driver and destination
    await MapProvider.fitBounds(_mapController!, [
      LatLng(dLat, dLng),
      LatLng(_destLat, _destLng),
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

  Future<void> _completeTrip(BuildContext context) async {
    await BlocProvider.of<RideFlowCubit>(
      context,
    ).endRide(distanceKm: widget.distance, durationMinutes: 10);
    if (context.mounted) {
      context.pushReplacementNamed(
        'CompleteTripDriver',
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 16),
              child: _buildStatusBadge(),
            ),
          ),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDestinationCard(),
                  const SizedBox(height: 16),
                  _buildMetaRow(),
                  const SizedBox(height: 16),
                  _buildPassengerRow(),
                  const SizedBox(height: 24),
                  _buildCompleteButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.route, size: 13, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'IN TRANSIT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEADING TO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.dropoff,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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

  Widget _buildMetaRow() {
    return Row(
      children: [
        _chip(LucideIcons.map_pin, '${widget.distance.toStringAsFixed(1)} km'),
        const SizedBox(width: 10),
        _chip(LucideIcons.clock, widget.duration),
        const SizedBox(width: 10),
        _chip(LucideIcons.banknote, '₱${widget.fare.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
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

  Widget _buildPassengerRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.user,
              color: AppTheme.primaryColor,
              size: 18,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'Aboard',
                  style: TextStyle(fontSize: 12, color: AppTheme.tertiaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _completeTrip(context),
      child: Container(
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.complete,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppTheme.complete.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'COMPLETE TRIP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

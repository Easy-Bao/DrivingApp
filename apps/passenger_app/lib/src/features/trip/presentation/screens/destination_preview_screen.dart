import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/shared/widgets/map_zoom_controls_widget.dart';
import 'package:shared_core/shared_core.dart';

class DestinationPreviewScreen extends StatefulWidget {
  final PlaceModel destination;
  final String? preselectedRideType;
  final String? pickupAddress;

  const DestinationPreviewScreen({
    super.key,
    required this.destination,
    this.preselectedRideType,
    this.pickupAddress,
  });

  @override
  State<DestinationPreviewScreen> createState() =>
      _DestinationPreviewScreenState();
}

class _DestinationPreviewScreenState extends State<DestinationPreviewScreen> {
  AppMapController? _mapController;
  double? _userLat = LocationService.lastPosition?.latitude;
  double? _userLng = LocationService.lastPosition?.longitude;
  String _distance = '';
  String _duration = '';
  double _distanceKm = 0.0;
  Map<String, double> _fares = {};
  RouteModel? _route;
  bool _isLoadingRoute = false;
  bool _routeRendered = false;
  mapbox.PointAnnotationManager? _pickupMarker;
  mapbox.PointAnnotationManager? _destinationMarker;
  mapbox.PolylineAnnotationManager? _routeLine;

  @override
  void initState() {
    super.initState();
    unawaited(_initLocation());
  }

  @override
  void dispose() {
    unawaited(MapProvider.clearAnnotations(_pickupMarker));
    unawaited(MapProvider.clearAnnotations(_destinationMarker));
    unawaited(MapProvider.clearAnnotations(_routeLine));
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
      await _loadRoute();
    } else if (_userLat != null && _userLng != null) {
      await _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    if (_userLat == null || _userLng == null) return;
    if (_isLoadingRoute) return;
    _isLoadingRoute = true;

    try {
      final route = await MapProvider.getRoute(
        _userLat!,
        _userLng!,
        widget.destination.latitude,
        widget.destination.longitude,
      );

      if (!mounted || route == null) return;

      final km = route.distanceKm;
      final mins = (route.durationSeconds / 60.0).ceil();
      setState(() {
        _route = route;
        _distance = '${km.toStringAsFixed(1)} km';
        _duration = '$mins min';
        _distanceKm = km;
        _fares = {
          'Solo Ride': (km * 15 + 30),
          'Share-Bao': (km * 10 + 20),
          'Bao Premium': (km * 20 + 45),
        };
      });
      await _renderRoute();
    } finally {
      _isLoadingRoute = false;
    }
  }

  Future<void> _renderRoute() async {
    final controller = _mapController;
    final route = _route;
    if (controller == null || route == null || _routeRendered) return;
    if (route.polylinePoints.length < 2) return;

    _routeRendered = true;
    try {
      _pickupMarker = await MapProvider.addMarker(
        controller,
        _userLat!,
        _userLng!,
        label: 'Current location\nYou are here',
        isOrigin: true,
      );
      _destinationMarker = await MapProvider.addMarker(
        controller,
        widget.destination.latitude,
        widget.destination.longitude,
        label: 'Your destination\n${widget.destination.name}',
        isOrigin: false,
      );
      _routeLine = await MapProvider.addPolyline(
        controller,
        route.polylinePoints,
        color: AppTheme.primaryColor,
        width: 5.0,
      );
      final routePoints = route.polylinePoints
          .where((point) => point.length >= 2)
          .map((point) => LatLng(point[1], point[0]));
      await MapProvider.fitBounds(
        controller,
        [
          LatLng(_userLat!, _userLng!),
          LatLng(widget.destination.latitude, widget.destination.longitude),
          ...routePoints,
        ],
        padding: 80.0,
        maxZoom: 14.5,
      );
    } catch (error) {
      _routeRendered = false;
      debugPrint('Error rendering route preview: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullAddress = widget.destination.fullAddress;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapProvider.buildMapView(
              latitude: widget.destination.latitude,
              longitude: widget.destination.longitude,
              zoom: 14.5,
              onMapCreated: (controller) async {
                _mapController = controller;
                if (_route == null) {
                  await _loadRoute();
                } else {
                  await _renderRoute();
                }
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderSide),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.arrow_left,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 275,
            child: MapZoomControlsWidget(
              onZoomIn: () {
                if (_mapController != null) {
                  unawaited(MapProvider.zoomIn(_mapController!));
                }
              },
              onZoomOut: () {
                if (_mapController != null) {
                  unawaited(MapProvider.zoomOut(_mapController!));
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppTheme.neutralColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.map_pin,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.destination.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (fullAddress.isNotEmpty)
                              Text(
                                fullAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_distance.isNotEmpty && _duration.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.route,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _distance,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 18,
                            color: AppTheme.borderSide,
                          ),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _duration,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final params = <String, String>{
                          'destinationName': widget.destination.name,
                          'destinationLat': widget.destination.latitude
                              .toString(),
                          'destinationLng': widget.destination.longitude
                              .toString(),
                          'distance': _distance,
                          'duration': _duration,
                          'distanceKm': _distanceKm.toString(),
                        };
                        if (fullAddress.isNotEmpty) {
                          params['destinationAddress'] = fullAddress;
                        }
                        if (widget.pickupAddress != null) {
                          params['pickupAddress'] = widget.pickupAddress!;
                        }
                        if (widget.preselectedRideType != null) {
                          params['rideType'] = widget.preselectedRideType!;
                        }
                        unawaited(
                          context.pushNamed(
                            TripRoutes.rideSelection,
                            queryParameters: params,
                            extra: _fares,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Destination',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

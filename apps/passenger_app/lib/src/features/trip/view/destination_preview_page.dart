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

class DestinationPreviewPage extends StatefulWidget {
  final PlaceModel destination;
  final String? preselectedRideType;
  final String? pickupAddress;

  const DestinationPreviewPage({
    super.key,
    required this.destination,
    this.preselectedRideType,
    this.pickupAddress,
  });

  @override
  State<DestinationPreviewPage> createState() => _DestinationPreviewPageState();
}

class _DestinationPreviewPageState extends State<DestinationPreviewPage> {
  AppMapController? _mapController;
  double? _userLat = LocationService.lastPosition?.latitude;
  double? _userLng = LocationService.lastPosition?.longitude;
  double? _pickupLat;
  double? _pickupLng;
  String _distance = '';
  String _duration = '';
  double _distanceKm = 0.0;
  RouteModel? _route;
  bool _isLoadingRoute = false;
  bool _routeRendered = false;
  String? _routeError;
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
    if (pos != null) {
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
      await _loadRoute();
      return;
    }

    if (_userLat != null && _userLng != null) {
      await _loadRoute();
      return;
    }

    if (mounted) {
      setState(() {
        _routeError = 'We need your pickup location to calculate this route.';
      });
    }
  }

  Future<void> _loadRoute() async {
    if (_isLoadingRoute) return;
    final userLat = _userLat;
    final userLng = _userLng;
    if (userLat == null || userLng == null) {
      if (mounted) {
        setState(() {
          _routeError = 'We need your pickup location to calculate this route.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingRoute = true;
        _routeError = null;
        _routeRendered = false;
      });
    } else {
      _isLoadingRoute = true;
    }

    try {
      final route = await MapProvider.getRoute(
        userLat,
        userLng,
        widget.destination.latitude,
        widget.destination.longitude,
        preference: RoutePreference.shortest,
      );

      if (!mounted) return;
      if (route == null || !route.hasGeometry || route.durationSeconds <= 0) {
        setState(() {
          _route = null;
          _distance = '';
          _duration = '';
          _distanceKm = 0.0;
          _routeError =
              'We couldn’t load the route for this destination. Please try again.';
        });
        return;
      }

      final km = route.distanceKm;
      final mins = (route.durationSeconds / 60.0).ceil();
      final routeStart = route.startCoordinate;
      setState(() {
        _route = route;
        _pickupLat = routeStart?.lat ?? _userLat;
        _pickupLng = routeStart?.lng ?? _userLng;
        _distance = '${km.toStringAsFixed(1)} km';
        _duration = '$mins min';
        _distanceKm = km;
      });
      await _renderRoute();
    } catch (_) {
      if (mounted) {
        setState(() {
          _route = null;
          _distance = '';
          _duration = '';
          _distanceKm = 0.0;
          _routeError =
              'We couldn’t load the route for this destination. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      } else {
        _isLoadingRoute = false;
      }
    }
  }

  Future<void> _renderRoute() async {
    final controller = _mapController;
    final route = _route;
    if (controller == null || route == null || _routeRendered) return;
    final routePoints = route.validPolylinePoints;
    if (routePoints.length < 2) return;

    final pickupLat = _pickupLat ?? _userLat;
    final pickupLng = _pickupLng ?? _userLng;
    if (pickupLat == null || pickupLng == null) return;

    try {
      await MapProvider.clearAnnotations(_pickupMarker);
      await MapProvider.clearAnnotations(_destinationMarker);
      await MapProvider.clearAnnotations(_routeLine);
      _pickupMarker = await MapProvider.addMarker(
        controller,
        pickupLat,
        pickupLng,
        label: 'Pickup point\nDriver will meet you here',
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
        routePoints,
        color: AppTheme.primaryColor,
        width: 5.0,
      );
      await MapProvider.fitBounds(
        controller,
        [
          LatLng(pickupLat, pickupLng),
          LatLng(widget.destination.latitude, widget.destination.longitude),
          ...routePoints.map((point) => LatLng(point[1], point[0])),
        ],
        padding: 80.0,
        maxZoom: 14.5,
      );
      if (!mounted) return;
      setState(() {
        _routeRendered = true;
        _routeError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _routeRendered = false;
          _routeError =
              'We couldn’t display the route right now. Please try again.';
        });
      } else {
        _routeRendered = false;
      }
      debugPrint('Error rendering route preview: $error');
    }
  }

  void _retryRoute() {
    unawaited(_loadRoute());
  }

  Widget _buildRouteStatus() {
    final routeError = _routeError;
    if (_isLoadingRoute) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Calculating route…'),
          ],
        ),
      );
    }

    if (routeError == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.cancel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cancel.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.circle_alert,
            color: AppTheme.cancel,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              routeError,
              style: const TextStyle(
                color: AppTheme.cancel,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
          TextButton(onPressed: _retryRoute, child: const Text('Try again')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullAddress = widget.destination.fullAddress;
    final canConfirmDestination =
        _route != null && _routeRendered && !_isLoadingRoute;
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
                  _buildRouteStatus(),
                  if (_routeError != null || _isLoadingRoute)
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
                      onPressed: canConfirmDestination
                          ? () {
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
                                params['rideType'] =
                                    widget.preselectedRideType!;
                              }
                              final pickupLat = _pickupLat ?? _userLat;
                              final pickupLng = _pickupLng ?? _userLng;
                              if (pickupLat != null && pickupLng != null) {
                                params['pickupLat'] = pickupLat.toString();
                                params['pickupLng'] = pickupLng.toString();
                              }
                              unawaited(
                                context.pushNamed(
                                  TripRoutes.rideSelection,
                                  extra: {'destination': widget.destination},
                                  queryParameters: params,
                                ),
                              );
                            }
                          : _routeError != null
                          ? _retryRoute
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isLoadingRoute
                            ? 'Calculating route…'
                            : _routeError != null
                            ? 'Try again'
                            : canConfirmDestination
                            ? 'Confirm Destination'
                            : 'Preparing route…',
                        style: const TextStyle(
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

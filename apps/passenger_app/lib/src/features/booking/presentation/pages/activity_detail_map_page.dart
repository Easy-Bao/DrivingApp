import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/booking/booking_routes.dart';
import 'package:design_system/design_system.dart';

class ActivityDetailMapPage extends StatefulWidget {
  final String placeName;
  final String placeSubtitle;
  final double destinationLat;
  final double destinationLng;

  const ActivityDetailMapPage({
    super.key,
    required this.placeName,
    required this.placeSubtitle,
    required this.destinationLat,
    required this.destinationLng,
  });

  @override
  State<ActivityDetailMapPage> createState() => _ActivityDetailMapPageState();
}

class _ActivityDetailMapPageState extends State<ActivityDetailMapPage> {
  AppMapController? _mapController;
  String _fullAddress = '';
  bool _isLoading = true;
  bool _routeDataLoaded = false;
  Future<void>? _routeDataRequest;
  Future<void>? _routeRenderRequest;
  ({double lat, double lng})? _originCoordinate;
  Route? _route;

  @override
  void initState() {
    super.initState();
    _ensureRouteDataLoaded();
  }

  void _ensureRouteDataLoaded() {
    if (_routeDataLoaded) {
      unawaited(_ensureRouteDataRendered());
      return;
    }
    if (_routeDataRequest != null) return;

    final request = _loadRouteData();
    _routeDataRequest = request;
    unawaited(
      request.whenComplete(() {
        if (identical(_routeDataRequest, request)) {
          _routeDataRequest = null;
        }
      }),
    );
  }

  Future<void> _loadRouteData() async {
    try {
      final position = await LocationService.getCurrentPosition();
      final origin = (
        lat: position?.latitude ?? widget.destinationLat,
        lng: position?.longitude ?? widget.destinationLng,
      );

      _originCoordinate = origin;
      final placeRequest = MapProvider.getPlaceFromCoordinates(
        widget.destinationLat,
        widget.destinationLng,
      );
      final routeRequest = MapProvider.getRoute(
        origin.lat,
        origin.lng,
        widget.destinationLat,
        widget.destinationLng,
      );
      final place = await placeRequest;
      _route = await routeRequest;

      if (!mounted) return;
      _routeDataLoaded = true;
      setState(() {
        _fullAddress = place?.fullAddress ?? widget.placeSubtitle;
        _isLoading = false;
      });
      await _ensureRouteDataRendered();
    } catch (error) {
      if (!mounted) return;
      _routeDataLoaded = true;
      setState(() {
        _fullAddress = widget.placeSubtitle;
        _isLoading = false;
      });
      debugPrint('Unable to load activity route: $error');
    }
  }

  Future<void> _ensureRouteDataRendered() {
    final ongoingRequest = _routeRenderRequest;
    if (ongoingRequest != null) return ongoingRequest;

    final request = _renderRouteData();
    _routeRenderRequest = request;
    unawaited(
      request.whenComplete(() {
        if (identical(_routeRenderRequest, request)) {
          _routeRenderRequest = null;
        }
      }),
    );
    return request;
  }

  Future<void> _renderRouteData() async {
    final controller = _mapController;
    final origin = _originCoordinate;
    if (controller == null || origin == null) return;
    final routeColor = context.colorScheme.onSurface;

    try {
      await MapProvider.addMarker(
        controller,
        origin.lat,
        origin.lng,
        isOrigin: true,
        color: TripMapMarkerStyle.ownLocation,
      );
      await MapProvider.addMarker(
        controller,
        widget.destinationLat,
        widget.destinationLng,
        color: TripMapMarkerStyle.tripLocation,
      );
      await MapProvider.fitBounds(controller, [
        LatLng(origin.lat, origin.lng),
        LatLng(widget.destinationLat, widget.destinationLng),
      ]);

      final route = _route;
      if (route == null) return;
      await MapProvider.addPolyline(
        controller,
        route.polylinePoints,
        color: routeColor,
        width: 5.0,
      );
    } catch (error) {
      debugPrint('Unable to render activity route: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapProvider.buildMapView(
              latitude: widget.destinationLat,
              longitude: widget.destinationLng,
              zoom: 13.0,
              onMapCreated: (c) {
                _mapController = c;
                _ensureRouteDataLoaded();
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildTripBackButton(context, () => context.pop()),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: context.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          LucideIcons.map_pin,
                          color: context.colorScheme.onSurface,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.placeName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading ? 'Loading...' : _fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CompactRouteTimelineWidget(
                    pickup: 'Current Location',
                    dropoff: widget.placeName,
                    pickupLabel: 'From',
                    dropoffLabel: 'Destination',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final place = Place(
                          id: 'activity_place_${widget.placeName.replaceAll(' ', '_')}',
                          name: widget.placeName,
                          fullAddress: widget.placeSubtitle,
                          latitude: widget.destinationLat,
                          longitude: widget.destinationLng,
                        );
                        unawaited(
                          context.pushNamed(
                            BookingRoutes.rideSelection,
                            extra: place,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.onSurface,
                        foregroundColor: context.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: context.colorScheme.surface,
      elevation: 2,
      shadowColor: context.colorScheme.onSurface.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}

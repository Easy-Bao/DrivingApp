import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

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

  @override
  void initState() {
    super.initState();
    unawaited(_loadRouteData());
  }

  Future<void> _loadRouteData() async {
    final position = await LocationService.getCurrentPosition();
    final originLat = position?.latitude ?? widget.destinationLat;
    final originLng = position?.longitude ?? widget.destinationLng;

    final place = await MapProvider.getPlaceFromCoordinates(
      widget.destinationLat,
      widget.destinationLng,
    );

    final route = await MapProvider.getRoute(
      originLat,
      originLng,
      widget.destinationLat,
      widget.destinationLng,
    );

    if (!mounted) return;
    setState(() {
      _fullAddress = place?.fullAddress ?? widget.placeSubtitle;
      _isLoading = false;
    });

    if (_mapController != null) {
      await MapProvider.addMarker(
        _mapController!,
        originLat,
        originLng,
        isOrigin: true,
      );
      await MapProvider.addMarker(
        _mapController!,
        widget.destinationLat,
        widget.destinationLng,
      );
      await MapProvider.fitBounds(_mapController!, [
        LatLng(originLat, originLng),
        LatLng(widget.destinationLat, widget.destinationLng),
      ]);
      if (route != null) {
        await MapProvider.addPolyline(
          _mapController!,
          route.polylinePoints,
          color: AppTheme.primaryColor,
          width: 5.0,
        );
      }
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
              latitude: widget.destinationLat,
              longitude: widget.destinationLng,
              zoom: 13.0,
              onMapCreated: (c) async {
                _mapController = c;
                if (!_isLoading) await _loadRouteData();
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: AppBackButtonWidget(onPressed: () => context.pop()),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                        color: AppTheme.borderSide,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.neutralColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.map_pin,
                          color: AppTheme.primaryColor,
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
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading ? 'Loading...' : _fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
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
                        final place = PlaceModel(
                          id: 'activity_place_${widget.placeName.replaceAll(' ', '_')}',
                          name: widget.placeName,
                          fullAddress: widget.placeSubtitle,
                          latitude: widget.destinationLat,
                          longitude: widget.destinationLng,
                        );
                        unawaited(
                          context.pushNamed(
                            TripRoutes.rideSelection,
                            extra: place,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
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

/// Activity Detail Map Screen: displays route map and details for past passenger trips.
import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/shared/widgets/custom_toast.dart';

class ActivityDetailMapScreen extends StatefulWidget {
  final String placeName;
  final String placeSubtitle;
  final double destinationLat;
  final double destinationLng;

  const ActivityDetailMapScreen({
    super.key,
    required this.placeName,
    required this.placeSubtitle,
    required this.destinationLat,
    required this.destinationLng,
  });

  @override
  State<ActivityDetailMapScreen> createState() =>
      _ActivityDetailMapScreenState();
}

class _ActivityDetailMapScreenState extends State<ActivityDetailMapScreen> {
  AppMapController? _mapController;
  String _distance = '—';
  String _duration = '—';
  String _fullAddress = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRouteData());
  }

  Future<void> _loadRouteData() async {
    final position = await LocationService.getCurrentPosition();
    final originLat = position?.latitude ?? 7.8307;
    final originLng = position?.longitude ?? 123.4370;

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
      if (route != null) {
        _distance = '${route.distanceKm.toStringAsFixed(1)} km';
        final mins = route.estimatedTime.inMinutes;
        _duration = mins < 60 ? '$mins min' : '${mins ~/ 60}h ${mins % 60}m';
      }
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
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
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.arrow_left,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.neutralColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderSide),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStat(
                            LucideIcons.navigation,
                            'Distance',
                            _isLoading ? '...' : _distance,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.borderSide,
                        ),
                        Expanded(
                          child: _buildStat(
                            LucideIcons.clock,
                            'ETA',
                            _isLoading ? '...' : _duration,
                          ),
                        ),
                      ],
                    ),
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
                        context.pushNamed('DestinationPreview', extra: place);
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

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.tertiaryColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:core_models/core_models.dart';
import 'package:passenger_app/core/services/location_service.dart';
import 'package:passenger_app/core/services/map_provider.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DestinationPreviewScreen extends StatefulWidget {
  final PlaceModel destination;

  const DestinationPreviewScreen({super.key, required this.destination});

  @override
  State<DestinationPreviewScreen> createState() =>
      _DestinationPreviewScreenState();
}

class _DestinationPreviewScreenState extends State<DestinationPreviewScreen> {
  AppMapController? _mapController;
  String _distance = '—';
  String _duration = '—';
  double _distanceKm = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRoute());
  }

  Future<void> _loadRoute() async {
    final pos = await LocationService.getCurrentPosition();
    final oLat = pos?.latitude ?? 7.8307;
    final oLng = pos?.longitude ?? 123.4370;

    final route = await MapProvider.getRoute(
      oLat,
      oLng,
      widget.destination.latitude,
      widget.destination.longitude,
    );

    if (!mounted) return;
    setState(() {
      if (route != null) {
        _distanceKm = route.distanceKm;
        _distance = '${route.distanceKm.toStringAsFixed(1)} km';
        final m = route.estimatedTime.inMinutes;
        _duration = m < 60 ? '$m min' : '${m ~/ 60}h ${m % 60}m';
      }
      _isLoading = false;
    });

    if (_mapController != null) {
      await MapProvider.addMarker(_mapController!, oLat, oLng, isOrigin: true);
      await MapProvider.addMarker(
        _mapController!,
        widget.destination.latitude,
        widget.destination.longitude,
      );
      await MapProvider.fitBounds(_mapController!, [
        LatLng(oLat, oLng),
        LatLng(widget.destination.latitude, widget.destination.longitude),
      ]);
      if (route != null && route.polylinePoints.isNotEmpty) {
        final points = route.polylinePoints;
        dynamic currentManager;

        final chunkSize = (points.length / 20).ceil().clamp(2, 50).toInt();
        const int delayMs = 100;

        for (int i = 0; i < points.length; i += chunkSize) {
          if (!mounted) break;
          final endIdx = (i + chunkSize < points.length)
              ? i + chunkSize
              : points.length;
          final segment = points.sublist(0, endIdx);

          final newManager = await MapProvider.addAnimatedPolylineSegment(
            _mapController!,
            segment,
            color: AppTheme.primaryColor,
            width: 5.0,
          );

          if (currentManager != null) {
            await MapProvider.clearAnnotations(currentManager);
          }
          currentManager = newManager;

          await Future.delayed(const Duration(milliseconds: delayMs));
        }
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
            height: MediaQuery.of(context).size.height * 0.6,
            child: MapProvider.buildMapView(
              latitude: widget.destination.latitude,
              longitude: widget.destination.longitude,
              zoom: 13.0,
              onMapCreated: (c) async {
                _mapController = c;
                if (!_isLoading) await _loadRoute();
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.borderSide,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.neutralColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          LucideIcons.map_pin,
                          color: AppTheme.primaryColor,
                          size: 20,
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
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.destination.fullAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _chip(
                        LucideIcons.navigation,
                        _isLoading ? '...' : _distance,
                      ),
                      const SizedBox(width: 10),
                      _chip(LucideIcons.clock, _isLoading ? '...' : _duration),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.pushNamed(
                              'RideSelection',
                              extra: {
                                'destination': widget.destination,
                                'distance': _distance,
                                'duration': _duration,
                                'distanceKm': _distanceKm,
                              },
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
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

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.tertiaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

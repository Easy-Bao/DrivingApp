import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/features/trip_booking/trip_routes.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:shared_ui/shared_ui.dart';

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
  String _distance = '—';
  String _duration = '—';
  double _distanceKm = 0.0;
  bool _isLoading = true;
  Map<String, double> _fares = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadRoute());
  }

  Future<void> _loadRoute() async {
    final pos = await LocationService.getCurrentPosition();
    final oLat = pos?.latitude ?? widget.destination.latitude;
    final oLng = pos?.longitude ?? widget.destination.longitude;

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
        final mapMarker = route.estimatedTime.inMinutes;
        _duration = mapMarker < 60
            ? '$mapMarker min'
            : '${mapMarker ~/ 60}h ${mapMarker % 60}m';
      }
    });

    if (route != null) {
      final mins = route.estimatedTime.inMinutes.toDouble();
      final estimates = await Future.wait([
        getIt<PassengerApiService>().fetchFareEstimate(
          rideType: 'Solo Ride',
          distanceKm: route.distanceKm,
          durationMinutes: mins,
        ),
        getIt<PassengerApiService>().fetchFareEstimate(
          rideType: 'Share-Bao',
          distanceKm: route.distanceKm,
          durationMinutes: mins,
        ),
        getIt<PassengerApiService>().fetchFareEstimate(
          rideType: 'Bao Premium',
          distanceKm: route.distanceKm,
          durationMinutes: mins,
        ),
      ]);

      double solo = 20.0 + route.distanceKm * 10;
      double share = 15.0 + route.distanceKm * 7;
      double premium = 35.0 + route.distanceKm * 15;

      if (estimates[0] != null) {
        solo = (estimates[0]!['total_fare'] as num).toDouble();
      }
      if (estimates[1] != null) {
        share = (estimates[1]!['total_fare'] as num).toDouble();
      }
      if (estimates[2] != null) {
        premium = (estimates[2]!['total_fare'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _fares = {
            'Solo Ride': solo,
            'Share-Bao': share,
            'Bao Premium': premium,
          };
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

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

        for (int index = 0; index < points.length; index += chunkSize) {
          if (!mounted) break;
          final endIdx = (index + chunkSize < points.length)
              ? index + chunkSize
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
          Positioned.fill(
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.chevron_left,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
                          : () {
                              if (widget.preselectedRideType != null) {
                                unawaited(
                                  context.pushNamed(
                                    TripRoutes.findingDriver,
                                    extra: {
                                      'rideType': widget.preselectedRideType!,
                                      'fare':
                                          _fares[widget.preselectedRideType!] ??
                                          (20.0 + _distanceKm * 10),
                                      'destination': widget.destination,
                                      'distance': _distance,
                                      'duration': _duration,
                                      'pickupAddress':
                                          widget.pickupAddress ??
                                          'Current Location',
                                    },
                                  ),
                                );
                              } else {
                                unawaited(
                                  context.pushNamed(
                                    TripRoutes.rideSelection,
                                    extra: {
                                      'destination': widget.destination,
                                      'distance': _distance,
                                      'duration': _duration,
                                      'distanceKm': _distanceKm,
                                      'fares': _fares,
                                      'pickupAddress':
                                          widget.pickupAddress ??
                                          'Current Location',
                                    },
                                  ),
                                );
                              }
                            },
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

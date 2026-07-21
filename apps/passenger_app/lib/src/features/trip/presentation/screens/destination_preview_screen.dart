import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
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
  Map<String, double> _fares = {};

  @override
  void initState() {
    super.initState();
    _computeInitialEstimates();
    unawaited(_loadRoute());
  }

  void _computeInitialEstimates() {
    const defaultDist = 2.5;
    const defaultMins = 8.0;
    setState(() {
      _distanceKm = defaultDist;
      _distance = '$defaultDist km';
      _duration = '${defaultMins.toInt()} min';
      _fares = {
        'Solo Ride': 20.0 + (defaultDist * 10),
        'Share-Bao': 15.0 + (defaultDist * 7),
        'Bao Premium': 35.0 + (defaultDist * 15),
      };
    });
  }

  Future<void> _loadRoute() async {
    final pos = await LocationService.getCurrentPosition();
    final oLat = pos?.latitude ?? widget.destination.latitude;
    final oLng = pos?.longitude ?? widget.destination.longitude;

    if (pos != null) {
      final meters = await LocationService.distanceBetween(
        oLat,
        oLng,
        widget.destination.latitude,
        widget.destination.longitude,
      );
      final approxKm = meters / 1000.0;
      if (approxKm > 0 && mounted) {
        final approxMins = (approxKm * 3).clamp(3.0, 120.0);
        setState(() {
          _distanceKm = approxKm;
          _distance = '${approxKm.toStringAsFixed(1)} km';
          _duration = '${approxMins.round()} min';
          _fares = {
            'Solo Ride': 20.0 + (approxKm * 10),
            'Share-Bao': 15.0 + (approxKm * 7),
            'Bao Premium': 35.0 + (approxKm * 15),
          };
        });
      }
    }

    final route = await MapProvider.getRoute(
      oLat,
      oLng,
      widget.destination.latitude,
      widget.destination.longitude,
    );

    if (!mounted) return;
    if (route != null) {
      setState(() {
        _distanceKm = route.distanceKm;
        _distance = '${route.distanceKm.toStringAsFixed(1)} km';
        final mins = route.estimatedTime.inMinutes;
        _duration = mins < 60 ? '$mins min' : '${mins ~/ 60}h ${mins % 60}m';
      });

      final minsDouble = route.estimatedTime.inMinutes.toDouble();
      try {
        final estimates = await Future.wait([
          Modular.get<BiddingRemoteDataSource>().fetchFareEstimate(
            rideType: 'Solo Ride',
            distanceKm: route.distanceKm,
            durationMinutes: minsDouble,
          ),
          Modular.get<BiddingRemoteDataSource>().fetchFareEstimate(
            rideType: 'Share-Bao',
            distanceKm: route.distanceKm,
            durationMinutes: minsDouble,
          ),
          Modular.get<BiddingRemoteDataSource>().fetchFareEstimate(
            rideType: 'Bao Premium',
            distanceKm: route.distanceKm,
            durationMinutes: minsDouble,
          ),
        ]);

        double solo = 20.0 + route.distanceKm * 10;
        double share = 15.0 + route.distanceKm * 7;
        double premium = 35.0 + route.distanceKm * 15;

        if (estimates[0] != null && estimates[0]!['total_fare'] != null) {
          solo = (estimates[0]!['total_fare'] as num).toDouble();
        }
        if (estimates[1] != null && estimates[1]!['total_fare'] != null) {
          share = (estimates[1]!['total_fare'] as num).toDouble();
        }
        if (estimates[2] != null && estimates[2]!['total_fare'] != null) {
          premium = (estimates[2]!['total_fare'] as num).toDouble();
        }

        if (mounted) {
          setState(() {
            _fares = {
              'Solo Ride': solo,
              'Share-Bao': share,
              'Bao Premium': premium,
            };
          });
        }
      } catch (_) {}
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
        const int delayMs = 50;

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
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapProvider.buildMapView(
              latitude: widget.destination.latitude,
              longitude: widget.destination.longitude,
              zoom: 13.0,
              onMapCreated: (c) async {
                _mapController = c;
                await _loadRoute();
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.arrow_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F294A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          LucideIcons.map_pin,
                          color: Color(0xFF2F80ED),
                          size: 22,
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
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.destination.fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _actionPill(
                          LucideIcons.navigation,
                          'Ride now',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionPill(
                          LucideIcons.clock,
                          'Schedule',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
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
                                  widget.pickupAddress ?? 'Current Location',
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book ride',
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

  Widget _actionPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

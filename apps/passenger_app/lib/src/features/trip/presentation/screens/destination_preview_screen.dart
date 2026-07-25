import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:fare_services/fare_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
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
      _fares = FareCalculatorHelper.estimateAllFares(
        distanceKm: defaultDist,
        durationMinutes: defaultMins,
      );
    });
    unawaited(_fetchServerFares(defaultDist, defaultMins));
  }

  Future<void> _fetchServerFares(double distanceKm, double durationMinutes) async {
    try {
      final fareRemoteDataSource = Modular.get<FareRemoteDataSource>();
      final res = await fareRemoteDataSource.fetchFareEstimates(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );

      final rawData = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      final estimatesList = rawData['estimates'] as List?;
      final Map<String, double> fetchedFares = {};

      if (estimatesList != null) {
        for (final item in estimatesList) {
          if (item is Map<String, dynamic>) {
            final type = item['serviceType'] as String? ?? item['service_type'] as String?;
            final fare = (item['totalFare'] ?? item['total_fare']) as num?;
            if (type != null && fare != null) {
              fetchedFares[type] = fare.toDouble();
            }
          }
        }
      }

      if (fetchedFares.isNotEmpty && mounted) {
        setState(() {
          _fares = fetchedFares;
        });
      }
    } catch (error) {
      debugPrint('Error fetching server fare quotes: $error');
    }
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
          _fares = FareCalculatorHelper.estimateAllFares(
            distanceKm: approxKm,
            durationMinutes: approxMins,
          );
        });
        unawaited(_fetchServerFares(approxKm, approxMins));
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
      final mins = route.estimatedTime.inMinutes.toDouble();
      setState(() {
        _distanceKm = route.distanceKm;
        _distance = '${route.distanceKm.toStringAsFixed(1)} km';
        _duration = mins < 60 ? '${mins.toInt()} min' : '${mins ~/ 60}h ${(mins % 60).toInt()}m';
        _fares = FareCalculatorHelper.estimateAllFares(
          distanceKm: route.distanceKm,
          durationMinutes: mins,
        );
      });
      unawaited(_fetchServerFares(route.distanceKm, mins));
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
              onMapCreated: (_) async {
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
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.chevron_left,
                      color: AppTheme.primaryColor,
                      size: 22,
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
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          LucideIcons.map_pin,
                          color: AppTheme.primaryColor,
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
                                color: AppTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.destination.fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.neutralColor,
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
}

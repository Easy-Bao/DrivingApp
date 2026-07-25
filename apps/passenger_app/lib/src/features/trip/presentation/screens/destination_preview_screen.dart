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
  double? _userLat = LocationService.lastPosition?.latitude;
  double? _userLng = LocationService.lastPosition?.longitude;
  String _distance = '';
  String _duration = '';
  double _distanceKm = 0.0;
  Map<String, double> _fares = {};

  @override
  void initState() {
    super.initState();
    unawaited(_initLocation());
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

    final route = await MapProvider.getRoute(
      _userLat!,
      _userLng!,
      widget.destination.latitude,
      widget.destination.longitude,
    );

    if (mounted && route != null) {
      final km = route.distanceKm;
      final mins = (route.durationSeconds / 60.0).ceil();
      final distanceStr = '${km.toStringAsFixed(1)} km';
      final durationStr = '$mins min';

      final fareRepo = Modular.get<FareRepository>();
      final soloResult = await fareRepo.getFareQuote(
        distanceKm: km,
        durationMinutes: mins.toDouble(),
        rideType: 'Solo Ride',
      );
      final shareResult = await fareRepo.getFareQuote(
        distanceKm: km,
        durationMinutes: mins.toDouble(),
        rideType: 'Share-Bao',
      );
      final premResult = await fareRepo.getFareQuote(
        distanceKm: km,
        durationMinutes: mins.toDouble(),
        rideType: 'Bao Premium',
      );

      final Map<String, double> calculatedFares = {};
      soloResult.fold(
        (_) {},
        (quote) => calculatedFares['Solo Ride'] = quote.breakdown.totalFare,
      );
      shareResult.fold(
        (_) {},
        (quote) => calculatedFares['Share-Bao'] = quote.breakdown.totalFare,
      );
      premResult.fold(
        (_) {},
        (quote) => calculatedFares['Bao Premium'] = quote.breakdown.totalFare,
      );

      setState(() {
        _distance = distanceStr;
        _duration = durationStr;
        _distanceKm = km;
        _fares = calculatedFares;
      });
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
              zoom: 14.5,
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderSide),
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
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
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
                        color: AppTheme.borderSide,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.neutralColor,
                          borderRadius: BorderRadius.circular(16),
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
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.destination.fullAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.tertiaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36),
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

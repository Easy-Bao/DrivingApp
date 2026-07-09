/// Ride Selection Screen: displays a map route preview and list of ride tier options with dynamic fares for selection.
library;

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';

class RideSelectionScreen extends StatefulWidget {
  final PlaceModel destination;
  final String distance;
  final String duration;
  final double distanceKm;
  final Map<String, double>? fares;
  final String? pickupAddress;

  const RideSelectionScreen({
    super.key,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.distanceKm,
    this.fares,
    this.pickupAddress,
  });

  @override
  State<RideSelectionScreen> createState() => _RideSelectionScreenState();
}

class _RideSelectionScreenState extends State<RideSelectionScreen> {
  int _selectedIdx = 0;
  late final List<_RideOption> _options;
  AppMapController? _mapController;

  @override
  void initState() {
    super.initState();
    final km = widget.distanceKm;
    final formattedFare = widget.fares ?? {};
    _options = [
      _RideOption(
        'Solo Ride',
        'Direct booking, just you',
        LucideIcons.bike,
        formattedFare['Solo Ride'] ?? (20.0 + km * 10),
        '3 min',
        null,
      ),
      _RideOption(
        'Share-Bao',
        'Pasabay, split the fare',
        LucideIcons.users,
        formattedFare['Share-Bao'] ?? (15.0 + km * 7),
        '5 min',
        'Cheapest',
      ),
      _RideOption(
        'Bao Premium',
        'Priority pickup, top rated',
        LucideIcons.crown,
        formattedFare['Bao Premium'] ?? (35.0 + km * 15),
        '2 min',
        'Fastest',
      ),
    ];
  }

  Future<void> _drawRoute() async {
    if (_mapController == null) return;

    final pickupLat = LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final pickupLng = LocationService.lastPosition?.longitude ?? widget.destination.longitude;
    final destLat = widget.destination.latitude;
    final destLng = widget.destination.longitude;

    try {
      final route = await MapProvider.getRoute(
        pickupLat,
        pickupLng,
        destLat,
        destLng,
      );
      if (route != null && mounted) {
        await MapProvider.addMarker(
          _mapController!,
          pickupLat,
          pickupLng,
          isOrigin: true,
        );
        await MapProvider.addMarker(
          _mapController!,
          destLat,
          destLng,
          isOrigin: false,
        );
        await MapProvider.addPolyline(
          _mapController!,
          route.polylinePoints,
          color: AppTheme.primaryColor,
          width: 5.0,
        );
        await MapProvider.fitBounds(_mapController!, [
          LatLng(pickupLat, pickupLng),
          LatLng(destLat, destLng),
        ], padding: 60.0);
      }
    } catch (error) {
      debugPrint('Error drawing route preview: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _options[_selectedIdx];
    final defaultLat = LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final defaultLng = LocationService.lastPosition?.longitude ?? widget.destination.longitude;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppTheme.neutralColor,
              child: SizedBox.expand(
                child: MapProvider.buildMapView(
                  latitude: defaultLat,
                  longitude: defaultLng,
                  zoom: 13.5,
                  interactive: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    unawaited(_drawRoute());
                  },
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: AppTheme.outlineBorderColor,
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.tertiaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pickupAddress ?? 'Current Location',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.destination.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.distance,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.tertiaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.duration,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'CHOOSE YOUR RIDE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...List.generate(_options.length, (i) {
                    final mapOffset = _options[i];
                    final isSel = i == _selectedIdx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIdx = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.primaryColor.withValues(alpha: 0.05)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel
                                ? AppTheme.primaryColor
                                : AppTheme.borderSide,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppTheme.primaryColor
                                    : AppTheme.neutralColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                mapOffset.icon,
                                size: 20,
                                color: isSel
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        mapOffset.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      if (mapOffset.badge != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: mapOffset.badge == 'Cheapest'
                                                ? AppTheme.complete.withValues(
                                                    alpha: 0.15,
                                                  )
                                                : AppTheme.tertiaryColor
                                                      .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            mapOffset.badge!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: mapOffset.badge == 'Cheapest'
                                                  ? AppTheme.complete
                                                  : AppTheme.tertiaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mapOffset.subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₱${mapOffset.fare.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  '~${mapOffset.eta}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isSel) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 4),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => context.pushNamed(
                            'FindingDriver',
                            extra: {
                              'rideType': sel.name,
                              'fare': sel.fare,
                              'destination': widget.destination,
                              'distance': widget.distance,
                              'duration': widget.duration,
                              'pickupAddress': widget.pickupAddress ?? 'Current Location',
                            },
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Book ${sel.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

class _RideOption {
  final String name, subtitle, eta;
  final IconData icon;
  final double fare;
  final String? badge;
  _RideOption(
    this.name,
    this.subtitle,
    this.icon,
    this.fare,
    this.eta,
    this.badge,
  );
}

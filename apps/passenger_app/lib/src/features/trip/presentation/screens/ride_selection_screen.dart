import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:fare_services/fare_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/trip/presentation/widgets/ride_options_panel_widget.dart';
import 'package:shared_ui/shared_ui.dart';

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
  late final List<RideOptionData> _options;
  AppMapController? _mapController;

  @override
  void initState() {
    super.initState();
    final km = widget.distanceKm;
    final formattedFare = widget.fares ?? {};
    _options = [
      RideOptionData(
        name: 'Solo Ride',
        subtitle: 'Direct booking, just you',
        icon: LucideIcons.bike,
        fare: formattedFare['Solo Ride'] ??
            FareCalculatorHelper.estimateFare(
              serviceType: 'Solo Ride',
              distanceKm: km,
            ),
        eta: '3 min',
        badge: null,
      ),
      RideOptionData(
        name: 'Share-Bao',
        subtitle: 'Pasabay, split the fare',
        icon: LucideIcons.users,
        fare: formattedFare['Share-Bao'] ??
            FareCalculatorHelper.estimateFare(
              serviceType: 'Share-Bao',
              distanceKm: km,
            ),
        eta: '5 min',
        badge: 'Cheapest',
      ),
      RideOptionData(
        name: 'Bao Premium',
        subtitle: 'Priority pickup, top rated',
        icon: LucideIcons.crown,
        fare: formattedFare['Bao Premium'] ??
            FareCalculatorHelper.estimateFare(
              serviceType: 'Bao Premium',
              distanceKm: km,
            ),
        eta: '2 min',
        badge: 'Fastest',
      ),
    ];
  }

  Future<void> _drawRoute() async {
    if (_mapController == null) return;

    final pickupLat =
        LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final pickupLng =
        LocationService.lastPosition?.longitude ?? widget.destination.longitude;
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
    final defaultLat =
        LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final defaultLng =
        LocationService.lastPosition?.longitude ?? widget.destination.longitude;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
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
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 600.0;
                final sel = _options[_selectedIdx];

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 600.0 : double.infinity,
                  ),
                  child: RideOptionsPanelWidget(
                    options: _options,
                    selectedIndex: _selectedIdx,
                    onOptionSelected: (idx) {
                      setState(() {
                        _selectedIdx = idx;
                      });
                    },
                    onBookPressed: () {
                      unawaited(
                        context.pushNamed(
                          'FindingDriver',
                          extra: {
                            'rideType': sel.name,
                            'fare': sel.fare,
                            'destination': widget.destination,
                            'distance': widget.distance,
                            'duration': widget.duration,
                            'pickupAddress':
                                widget.pickupAddress ?? 'Current Location',
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

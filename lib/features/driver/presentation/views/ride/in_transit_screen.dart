import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:BaoRide/core/services/map_provider.dart';
import 'package:BaoRide/core/services/location_service.dart';
import 'package:BaoRide/features/driver/presentation/bloc/ride/ride_flow_cubit.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Screen displayed to the driver during passenger transit.
/// Displays a live Mapbox widget tracing the route to destination.
class InTransitScreen extends StatefulWidget {
  final String pickup, dropoff, duration;
  final double distance, fare;

  const InTransitScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen> {
  bool _initialized = false;

  void _onMapCreated(AppMapController controller) async {
    if (!_initialized) {
      _initialized = true;

      // Simulated coordinates for Pagadian City
      final pickupLat = LocationService.lastPosition?.latitude ?? 7.828282;
      final pickupLng = LocationService.lastPosition?.longitude ?? 123.434343;

      // Dropoff is displaced
      final dropoffLat = pickupLat - 0.009;
      final dropoffLng = pickupLng + 0.008;

      try {
        await MapProvider.addMarker(controller, pickupLat, pickupLng, isOrigin: true);
        await MapProvider.addMarker(controller, dropoffLat, dropoffLng, isOrigin: false);

        final route = await MapProvider.getRoute(pickupLat, pickupLng, dropoffLat, dropoffLng);
        if (route != null) {
          await MapProvider.addPolyline(controller, route.polylinePoints, color: AppTheme.primaryColor, width: 4.5);
        }

        await MapProvider.fitBounds(
          controller,
          [LatLng(pickupLat, pickupLng), LatLng(dropoffLat, dropoffLng)],
          padding: 60.0,
        );
      } catch (e) {
        debugPrint("Error drawing transit map: $e");
      }
    }
  }

  void _completTrip() async {
    await BlocProvider.of<RideFlowCubit>(context).endRide(
          distanceKm: widget.distance,
          durationMinutes: 10,
        );

    if (mounted) {
      context.pushReplacementNamed(
        "CompleteTripDriver",
        extra: {
          "pickup": widget.pickup,
          "dropoff": widget.dropoff,
          "distance": widget.distance,
          "fare": widget.fare,
          "duration": widget.duration,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultLat = LocationService.lastPosition?.latitude ?? 7.828282;
    final defaultLng = LocationService.lastPosition?.longitude ?? 123.434343;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Map Background (Replacing CustomPainter grid)
          Positioned.fill(
            bottom: 240,
            child: Container(
              color: AppTheme.neutralColor,
              child: MapProvider.buildMapView(
                latitude: defaultLat,
                longitude: defaultLng,
                zoom: 14.5,
                interactive: true,
                onMapCreated: _onMapCreated,
              ),
            ),
          ),

          // Header Status Badge
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {},
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
                        LucideIcons.navigation,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
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
                        Icon(LucideIcons.route, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "IN TRANSIT",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet details & Actions
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppTheme.tertiaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.dropoff,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip(LucideIcons.map_pin, "${widget.distance} km"),
                      const SizedBox(width: 10),
                      _chip(LucideIcons.clock, widget.duration),
                      const SizedBox(width: 10),
                      _chip(
                        LucideIcons.banknote,
                        "₱${widget.fare.toStringAsFixed(0)}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _completTrip,
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.complete,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.complete.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "COMPLETE TRIP",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
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

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.tertiaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:BaoRide/core/services/map_provider.dart';
import 'package:BaoRide/core/services/location_service.dart';
import 'package:BaoRide/features/driver/presentation/bloc/ride/ride_flow_cubit.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Screen displayed to the driver while en route to pickup the passenger.
/// Embeds a real Mapbox view with driving path from current location to pickup.
class EnRoutePickupScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;

  const EnRoutePickupScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<EnRoutePickupScreen> createState() => _EnRoutePickupScreenState();
}

class _EnRoutePickupScreenState extends State<EnRoutePickupScreen> {
  double _sliderVal = 0;
  bool _initialized = false;

  void _onMapCreated(AppMapController controller) async {
    if (!_initialized) {
      _initialized = true;

      // Simulated locations for Pagadian City
      final driverLat = LocationService.lastPosition?.latitude ?? 7.828282;
      final driverLng = LocationService.lastPosition?.longitude ?? 123.434343;

      // Pickup point is offset slightly
      final pickupLat = driverLat + 0.007;
      final pickupLng = driverLng - 0.006;

      try {
        await MapProvider.addMarker(controller, driverLat, driverLng, isOrigin: true);
        await MapProvider.addMarker(controller, pickupLat, pickupLng, isOrigin: false);

        final route = await MapProvider.getRoute(driverLat, driverLng, pickupLat, pickupLng);
        if (route != null) {
          await MapProvider.addPolyline(controller, route.polylinePoints, color: AppTheme.primaryColor, width: 4.5);
        }

        await MapProvider.fitBounds(
          controller,
          [LatLng(driverLat, driverLng), LatLng(pickupLat, pickupLng)],
          padding: 60.0,
        );
      } catch (e) {
        debugPrint("Error drawing en_route map elements: $e");
      }
    }
  }

  void _confirmArrival() {
    BlocProvider.of<RideFlowCubit>(context).arriveAtPickup("Juan D. Cruz");
    context.pushReplacementNamed("WaitingPassenger", extra: {
      "pickup": widget.pickup,
      "dropoff": widget.dropoff,
      "distance": widget.distance,
      "fare": widget.fare,
      "duration": widget.duration,
    });
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
            bottom: 300,
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

          // Header: Back button + Title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
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
                          )
                        ],
                      ),
                      child: const Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor, size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.navigation, size: 14, color: AppTheme.complete),
                        const SizedBox(width: 6),
                        Text(
                          "EN ROUTE",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.complete,
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

          // Bottom Sheet Panel
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
                  )
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
                  
                  // Passenger details
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(LucideIcons.user, color: AppTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Juan D. Cruz", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                            Text(
                              widget.pickup,
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions: Call & Chat
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          LucideIcons.phone,
                          "Call",
                          AppTheme.primaryColor,
                          Colors.white,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionBtn(
                          LucideIcons.message_circle,
                          "Chat",
                          AppTheme.neutralColor,
                          AppTheme.primaryColor,
                          () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Confirm arrival slider
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final maxW = constraints.maxWidth;
                      return Container(
                        height: 64,
                        width: maxW,
                        decoration: BoxDecoration(
                          color: AppTheme.complete.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                _sliderVal > 0.8 ? "Release to confirm" : "Slide to confirm arrival",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.complete.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            Positioned(
                              left: _sliderVal * (maxW - 64),
                              child: GestureDetector(
                                onHorizontalDragUpdate: (d) {
                                  setState(() => _sliderVal = ((_sliderVal + d.delta.dx / (maxW - 64)).clamp(0.0, 1.0)));
                                },
                                onHorizontalDragEnd: (_) {
                                  if (_sliderVal > 0.85) {
                                    _confirmArrival();
                                  } else {
                                    setState(() => _sliderVal = 0);
                                  }
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.complete,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.complete.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                      )
                                    ],
                                  ),
                                  child: const Icon(LucideIcons.chevron_right, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: bg == AppTheme.neutralColor ? Border.all(color: AppTheme.borderSide) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:location_service/location_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AcitivityTrackDriver extends StatefulWidget {
  const AcitivityTrackDriver({super.key});

  @override
  State<AcitivityTrackDriver> createState() => _AcitivityTrackDriverState();
}

class _AcitivityTrackDriverState extends State<AcitivityTrackDriver> {
  AppMapController? _mapController;
  bool _initialized = false;
  bool _routeDrawn = false;

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (!_initialized) {
      _initialized = true;
      _routeDrawn = false;
      final passengerLat = LocationService.lastPosition?.latitude ?? 7.828282;
      final passengerLng =
          LocationService.lastPosition?.longitude ?? 123.434343;

      // Start driver displaced slightly to simulate movement towards user
      final driverStartLat = passengerLat + 0.006;
      final driverStartLng = passengerLng - 0.005;

      unawaited(
        BlocProvider.of<TrackDriverCubit>(context).startTracking(
          startLat: driverStartLat,
          startLng: driverStartLng,
          endLat: passengerLat,
          endLng: passengerLng,
        ),
      );
    }
  }

  Future<void> _updateMapElements(
    double driverLat,
    double driverLng,
    List<List<double>>? routePoints,
  ) async {
    if (_mapController == null) return;
    final passengerLat = LocationService.lastPosition?.latitude ?? 7.828282;
    final passengerLng = LocationService.lastPosition?.longitude ?? 123.434343;

    try {
      if (!_routeDrawn && routePoints != null && routePoints.isNotEmpty) {
        _routeDrawn = true;
        await MapProvider.addPolyline(
          _mapController!,
          routePoints,
          color: AppTheme.primaryColor.withValues(alpha: 0.6),
          width: 5.0,
        );
      }

      // Clear or overwrite markers (in this simplified SDK version, we re-draw or fly to bounds)
      await MapProvider.addMarker(
        _mapController!,
        passengerLat,
        passengerLng,
        isOrigin: true,
      );
      await MapProvider.addMarker(
        _mapController!,
        driverLat,
        driverLng,
        isOrigin: false,
      );

      // Re-fit camera to keep both visible
      await MapProvider.fitBounds(_mapController!, [
        LatLng(passengerLat, passengerLng),
        LatLng(driverLat, driverLng),
      ], padding: 80.0);
    } catch (e) {
      debugPrint('Error updating track map: $e');
    }
  }

  void _handleCancelTrip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Cancel Trip?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this trip? A cancellation fee may apply.',
          style: TextStyle(
            color: AppTheme.primaryColor.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep Ride',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              BlocProvider.of<TrackDriverCubit>(context).cancelTrip();
            },
            child: Text(
              'Cancel Trip',
              style: TextStyle(
                color: AppTheme.cancel,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passengerLat = LocationService.lastPosition?.latitude ?? 7.828282;
    final passengerLng = LocationService.lastPosition?.longitude ?? 123.434343;

    return BlocListener<TrackDriverCubit, TrackDriverState>(
      listener: (context, state) {
        if (state is TrackDriverInProgress) {
          unawaited(
            _updateMapElements(
              state.driverLat,
              state.driverLng,
              state.routePoints,
            ),
          );
        } else if (state is TrackDriverCompleted) {
          // Ride completed, transition to rating screen
          unawaited(context.pushNamed('PassengerRating'));
        } else if (state is TrackDriverCanceled) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Stack(
          children: [
            // Map area with tracking visualization
            Positioned.fill(
              bottom: 260,
              child: Container(
                color: AppTheme.neutralColor,
                child: MapProvider.buildMapView(
                  latitude: passengerLat,
                  longitude: passengerLng,
                  zoom: 14.5,
                  interactive: true,
                  onMapCreated: _onMapCreated,
                ),
              ),
            ),

            // Top navigation + ETA details
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        BlocProvider.of<TrackDriverCubit>(context).cancelTrip();
                        context.pop();
                      },
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
                    BlocBuilder<TrackDriverCubit, TrackDriverState>(
                      builder: (context, state) {
                        final eta = state is TrackDriverInProgress
                            ? state.eta
                            : 'Calculating...';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ARRIVING IN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                eta,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
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

            // Bottom panel
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                    // Drag handle
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

                    // Driver info row
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            color: AppTheme.primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xyrel D. Tenefrancia',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Bao Bao  •  ★ 4.9',
                                style: TextStyle(
                                  color: AppTheme.tertiaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderSide),
                          ),
                          child: const Text(
                            'ABC 1234',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: LucideIcons.message_circle,
                            label: 'Message',
                            backgroundColor: AppTheme.neutralColor,
                            foregroundColor: AppTheme.primaryColor,
                            borderColor: AppTheme.borderSide,
                            onTap: () {
                              unawaited(context.pushNamed('DriverChat'));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: LucideIcons.phone,
                            label: 'Call',
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            onTap: () {
                              // Direct action without double snackbar confirmation
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cancel button
                    GestureDetector(
                      onTap: _handleCancelTrip,
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cancel.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Text(
                          'Cancel Trip',
                          style: TextStyle(
                            color: AppTheme.cancel,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:passenger_app/core/models/driver/driver_model.dart';
import 'package:passenger_app/core/models/place/place_model.dart';
import 'package:passenger_app/core/services/location_service.dart';
import 'package:passenger_app/core/services/map_provider.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_bloc.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_event.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class FindingDriverScreen extends StatefulWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;

  const FindingDriverScreen({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
  });

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late AnimationController _dotCtrl;
  AppMapController? _mapController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (!_initialized) {
      _initialized = true;
      final lat = LocationService.lastPosition?.latitude ?? 7.828282;
      final lng = LocationService.lastPosition?.longitude ?? 123.434343;

      // Start search via Bloc
      BlocProvider.of<FindingDriverBloc>(
        context,
      ).add(SearchDriversEvent(lat: lat, lng: lng));

      // Draw initial simple pin for user
      MapProvider.addMarker(controller, lat, lng, isOrigin: true);
    }
  }

  void _showDriversOnMap(List<DriverModel> drivers) async {
    if (_mapController == null) return;

    // Add markers for all matching drivers on map
    for (final driver in drivers) {
      await MapProvider.addMarker(
        _mapController!,
        driver.lat,
        driver.lng,
        isOrigin: false,
      );
    }

    // Include passenger location inside bounds
    final passLat = LocationService.lastPosition?.latitude ?? 7.828282;
    final passLng = LocationService.lastPosition?.longitude ?? 123.434343;

    final boundsPoints = [
      LatLng(passLat, passLng),
    ].followedBy(drivers.map((d) => LatLng(d.lat, d.lng))).toList();

    await MapProvider.fitBounds(_mapController!, boundsPoints, padding: 80.0);
  }

  @override
  Widget build(BuildContext context) {
    final defaultLat = LocationService.lastPosition?.latitude ?? 7.828282;
    final defaultLng = LocationService.lastPosition?.longitude ?? 123.434343;

    return BlocListener<FindingDriverBloc, FindingDriverState>(
      listener: (context, state) {
        if (state is FindingDriverResults) {
          _showDriversOnMap(state.drivers);
        } else if (state is FindingDriverSelected) {
          // Navigate with the selected driver data
          context.pushReplacementNamed(
            'DriverMatched',
            extra: {
              'rideType': widget.rideType,
              'fare': widget.fare,
              'destination': widget.destination,
              'distance': widget.distance,
              'duration': widget.duration,
              'driverName': state.selectedDriver.name,
              'driverRating': state.selectedDriver.rating.toString(),
              'vehicleType': state.selectedDriver.vehicleType,
              'plateNumber': state.selectedDriver.plateNumber,
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Stack(
          children: [
            // Map Background (Replacing CustomPainter grid)
            Positioned.fill(
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

            // Radar overlay during search
            BlocBuilder<FindingDriverBloc, FindingDriverState>(
              builder: (context, state) {
                if (state is FindingDriverSearching ||
                    state is FindingDriverInitial) {
                  return Center(
                    child: AnimatedBuilder(
                      animation: _radarCtrl,
                      builder: (ctx, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            ...List.generate(3, (i) {
                              final t = (_radarCtrl.value + i * 0.33) % 1.0;
                              return Container(
                                width: 60 + t * 200,
                                height: 60 + t * 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.15 * (1 - t),
                                    ),
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.navigation,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GestureDetector(
                  onTap: () {
                    BlocProvider.of<FindingDriverBloc>(
                      context,
                    ).add(CancelSearchEvent());
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
              ),
            ),

            // Bottom Panel
            Align(
              alignment: Alignment.bottomCenter,
              child: BlocBuilder<FindingDriverBloc, FindingDriverState>(
                builder: (context, state) {
                  if (state is FindingDriverSearching ||
                      state is FindingDriverInitial) {
                    return Container(
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
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: AppTheme.borderSide,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _dotCtrl,
                            builder: (ctx, _) {
                              final dots =
                                  '.' * (1 + (_dotCtrl.value * 3).floor());
                              return Text(
                                'Finding your driver$dots',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Looking for ${widget.rideType} drivers nearby...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.neutralColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderSide),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.map_pin,
                                      size: 16,
                                      color: AppTheme.tertiaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 160,
                                      child: Text(
                                        widget.destination.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₱${widget.fare.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              BlocProvider.of<FindingDriverBloc>(
                                context,
                              ).add(CancelSearchEvent());
                              context.pop();
                            },
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.cancel.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Text(
                                'Cancel Search',
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
                    );
                  }

                  if (state is FindingDriverResults) {
                    return Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const Text(
                            'Select Nearest Driver',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Select from drivers matched by proximity algorithm',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.drivers.length,
                              itemBuilder: (context, index) {
                                final driver = state.drivers[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neutralColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.borderSide,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        LucideIcons.user,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    title: Text(
                                      driver.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${driver.vehicleType} • ${driver.plateNumber}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            Text(
                                              ' ${driver.rating.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${driver.distanceKm.toStringAsFixed(1)} km (~${driver.etaMinutes.ceil()} min)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      BlocProvider.of<FindingDriverBloc>(
                                        context,
                                      ).add(SelectDriverEvent(driver: driver));
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

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';

import 'dart:async';

import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/chat/chat_routes.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_event.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/en_route_pickup_panel_widget.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/trip_map_current_location_button.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/passenger_remote_data_source.dart';

import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = true;
  double? _passengerLat;
  double? _passengerLng;
  AppMapController? _mapController;
  Timer? _trackingTimer;

  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTrackingPassenger(BuildContext context) {
    final cubit = BlocProvider.of<RideFlowCubit>(context);
    final mapBloc = BlocProvider.of<LiveMapBloc>(context);
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      await _updateUnreadMessagesCount(cubit);
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      try {
        final loc = await Modular.get<TelemetryRemoteDataSource>()
            .fetchPassengerLocation(rideId);
        if (loc.isNotEmpty && loc['lat'] != null && loc['lng'] != null) {
          final pLat = (loc['lat'] as num).toDouble();
          final pLng = (loc['lng'] as num).toDouble();
          if (mounted) {
            setState(() {
              _passengerLat = pLat;
              _passengerLng = pLng;
            });
          }
        }
      } catch (_) {}

      try {
        final pos =
            await LocationService.getCurrentPosition() ??
            LocationService.lastPosition;
        if (pos != null) {
          if (mounted) {
            mapBloc.add(
              DispatchTelemetryLocationEvent(
                lat: pos.latitude,
                lng: pos.longitude,
              ),
            );
          }
          if (mounted && _passengerLat != null && _passengerLng != null) {
            mapBloc.add(
              UpdateLocationsAndDrawRouteEvent(
                driverLat: pos.latitude,
                driverLng: pos.longitude,
                passengerLat: _passengerLat!,
                passengerLng: _passengerLng!,
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _updateUnreadMessagesCount(RideFlowCubit cubit) async {
    try {
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      final driverIdentifier =
          await Modular.get<SecureSessionService>().readDriverId() ?? '';
      if (driverIdentifier.isEmpty) return;

      final chatRepo = Modular.get<ChatRepository>();
      final result = await chatRepo.fetchRoomMessages(rideId);
      result.fold((_) => null, (List<ChatMessage> messages) {
        final passengerChatMessagesList = messages
            .where((m) => m.senderId != driverIdentifier)
            .toList();
        final currentPassengerMessagesCount = passengerChatMessagesList.length;

        if (mounted) {
          setState(() {
            if (!_isInitialChatMessagesCountFetched) {
              _viewedPassengerMessagesCount = currentPassengerMessagesCount;
              _isInitialChatMessagesCountFetched = true;
            } else if (currentPassengerMessagesCount >
                _viewedPassengerMessagesCount) {
              _unreadChatMessagesCount =
                  currentPassengerMessagesCount - _viewedPassengerMessagesCount;
            }
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _loadRoute() async {
    final pos =
        await LocationService.getCurrentPosition() ??
        LocationService.lastPosition;
    if (!mounted) return;
    if (pos == null) return;

    final rideState = BlocProvider.of<RideFlowCubit>(context).state;
    if (rideState is RideFlowEnRoutePickup) {
      _passengerLat = rideState.pickupLat;
      _passengerLng = rideState.pickupLng;
    } else {
      final places = await MapProvider.searchPlaces(widget.pickup);
      if (places.isNotEmpty) {
        _passengerLat = places.first.latitude;
        _passengerLng = places.first.longitude;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    _startTrackingPassenger(context);
  }

  void _triggerDrawRoute(BuildContext context, double dLat, double dLng) {
    final passengerLat = _passengerLat;
    final passengerLng = _passengerLng;
    if (passengerLat == null || passengerLng == null) return;
    BlocProvider.of<LiveMapBloc>(context).add(
      UpdateLocationsAndDrawRouteEvent(
        driverLat: dLat,
        driverLng: dLng,
        passengerLat: passengerLat,
        passengerLng: passengerLng,
      ),
    );
  }

  void _onMapCreated(AppMapController controller, BuildContext context) {
    _mapController = controller;
    final pos = LocationService.lastPosition;
    final defaultLat = pos?.latitude ?? _passengerLat;
    final defaultLng = pos?.longitude ?? _passengerLng;
    if (defaultLat == null || defaultLng == null) return;

    BlocProvider.of<LiveMapBloc>(context).add(
      InitializeMapEvent(
        controller: controller,
        defaultLat: defaultLat,
        defaultLng: defaultLng,
      ),
    );

    if (!_isLoading) {
      _triggerDrawRoute(context, defaultLat, defaultLng);
    }
  }

  Future<void> _recenterMap() async {
    final controller = _mapController;
    final position =
        await LocationService.getCurrentPosition() ??
        LocationService.lastPosition;
    if (controller == null || position == null) return;
    await MapProvider.moveCamera(
      controller,
      position.latitude,
      position.longitude,
      zoom: 16,
    );
  }

  void _confirmArrival(BuildContext context) {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowEnRoutePickup
        ? state.passengerName
        : 'Passenger';
    final pickupState = state is RideFlowEnRoutePickup ? state : null;
    final pickupLat = pickupState?.pickupLat ?? _passengerLat;
    final pickupLng = pickupState?.pickupLng ?? _passengerLng;
    if (pickupLat == null || pickupLng == null) return;
    BlocProvider.of<RideFlowCubit>(context).arriveAtPickup(
      passengerName,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destLat: pickupState?.destLat,
      destLng: pickupState?.destLng,
    );
    context.pushReplacementNamed(
      TripRoutes.waitingPassenger,
      extra: {
        'pickup': widget.pickup,
        'dropoff': widget.dropoff,
        'distance': widget.distance,
        'fare': widget.fare,
        'duration': widget.duration,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveMapBloc>.value(
      value: Modular.get<LiveMapBloc>(),
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final position = LocationService.lastPosition;
          final pickupState = rideCubitState is RideFlowEnRoutePickup
              ? rideCubitState
              : null;
          final defaultLat = position?.latitude ?? pickupState?.pickupLat;
          final defaultLng = position?.longitude ?? pickupState?.pickupLng;
          if (defaultLat == null || defaultLng == null) {
            return const Scaffold(
              body: Center(child: Text('Pickup location is unavailable.')),
            );
          }

          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Stack(
              children: [
                Positioned.fill(
                  child: SizedBox.expand(
                    child: MapProvider.buildMapView(
                      latitude: defaultLat,
                      longitude: defaultLng,
                      zoom: 15.0,
                      onMapCreated: (c) => _onMapCreated(c, context),
                    ),
                  ),
                ),
                SafeArea(child: _buildHeader(context)),
                Positioned(
                  top: 112,
                  right: 20,
                  child: TripMapCurrentLocationButton(
                    onPressed: _mapController == null ? null : _recenterMap,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 600.0;
                      final rideState = BlocProvider.of<RideFlowCubit>(
                        context,
                      ).state;
                      final passengerName = rideState is RideFlowEnRoutePickup
                          ? rideState.passengerName
                          : 'Passenger';

                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 600.0 : double.infinity,
                        ),
                        child: EnRoutePickupPanelWidget(
                          pickup: widget.pickup,
                          dropoff: widget.dropoff,
                          passengerName: passengerName,
                          distance: widget.distance,
                          fare: widget.fare,
                          sliderValue: _sliderVal,
                          unreadChatMessagesCount: _unreadChatMessagesCount,
                          onSliderChanged: (val) {
                            setState(() {
                              _sliderVal = val;
                            });
                          },
                          onSliderCompleted: () => _confirmArrival(context),
                          onCallPressed: () async {
                            try {
                              final rideCubit = BlocProvider.of<RideFlowCubit>(
                                context,
                              );
                              final rideId = rideCubit.activeRideId ?? '';
                              if (rideId.isNotEmpty) {
                                final ride =
                                    await Modular.get<TripRemoteDataSource>()
                                        .getRideStatus(rideId);
                                final passengerId =
                                    ride['passenger_id'] as String?;
                                if (passengerId != null &&
                                    passengerId.isNotEmpty) {
                                  final passenger =
                                      await Modular.get<
                                            PassengerRemoteDataSource
                                          >()
                                          .fetchPassengerProfile(passengerId);
                                  final phone = passenger['phone'] as String?;
                                  if (phone != null && phone.isNotEmpty) {
                                    final uri = Uri.parse('tel:$phone');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  }
                                }
                              }
                            } catch (_) {}
                          },
                          onChatPressed: () async {
                            final rideId =
                                BlocProvider.of<RideFlowCubit>(
                                  context,
                                ).activeRideId ??
                                '';
                            final state = BlocProvider.of<RideFlowCubit>(
                              context,
                            ).state;
                            final pName = state is RideFlowEnRoutePickup
                                ? state.passengerName
                                : 'Passenger';
                            final driverId =
                                await Modular.get<SecureSessionService>()
                                    .readDriverId() ??
                                '';
                            if (!context.mounted) return;
                            setState(() {
                              _unreadChatMessagesCount = 0;
                            });
                            await context.pushNamed(
                              ChatRoutes.chat,
                              extra: {
                                'roomId': rideId,
                                'userId': driverId,
                                'peerName': pName,
                              },
                            );
                            if (!context.mounted) return;
                            _isInitialChatMessagesCountFetched = false;
                            await _updateUnreadMessagesCount(
                              BlocProvider.of<RideFlowCubit>(context),
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
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppTheme.neutralColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSide),
              ),
              child: const Icon(
                LucideIcons.arrow_left,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.complete.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.navigation,
                  size: 13,
                  color: AppTheme.complete,
                ),
                const SizedBox(width: 6),
                Text(
                  'EN ROUTE TO PICKUP',
                  style: TextStyle(
                    fontSize: 12,
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
    );
  }
}

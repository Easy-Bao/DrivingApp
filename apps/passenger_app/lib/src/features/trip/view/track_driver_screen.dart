import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_state.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/view/widgets/track_driver_panel_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityTrackDriverScreen extends StatefulWidget {
  final RideHistoryModel ride;

  const ActivityTrackDriverScreen({super.key, required this.ride});

  @override
  State<ActivityTrackDriverScreen> createState() =>
      _ActivityTrackDriverScreenState();
}

class _ActivityTrackDriverScreenState extends State<ActivityTrackDriverScreen> {
  AppMapController? _mapController;
  bool _initialized = false;
  bool _routeDrawn = false;
  RideStatus? _lastMapStatus;
  dynamic _passengerMarkerManager;
  dynamic _driverMarkerManager;
  dynamic _destinationMarkerManager;
  dynamic _routeLineManager;
  StreamSubscription<Position>? _locationSubscription;
  LiveMapBloc? _liveMapBloc;

  int _unreadChatMessagesCount = 0;
  int _viewedDriverMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;
  Timer? _chatMessagesPollTimer;

  @override
  void initState() {
    super.initState();
    _liveMapBloc = Modular.get<LiveMapBloc>();
    _startChatMessagesPolling();
  }

  @override
  void dispose() {
    if (_locationSubscription != null) {
      unawaited(_locationSubscription!.cancel());
    }
    unawaited(MapProvider.clearAnnotations(_routeLineManager));
    _chatMessagesPollTimer?.cancel();
    super.dispose();
  }

  void _startChatMessagesPolling() {
    _chatMessagesPollTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      await _updateUnreadMessagesCount();
    });
  }

  Future<void> _updateUnreadMessagesCount() async {
    try {
      final passengerIdentifier =
          await Modular.get<SecureSessionService>().readPassengerId() ?? '';
      if (passengerIdentifier.isEmpty) return;

      final chatRepository = Modular.get<ChatRepository>();
      final result = await chatRepository.fetchRoomMessages(widget.ride.id);

      result.fold((_) => null, (List<ChatMessage> messages) {
        final driverChatMessagesList = messages
            .where((m) => m.senderId != passengerIdentifier)
            .toList();
        final currentDriverMessagesCount = driverChatMessagesList.length;

        if (mounted) {
          setState(() {
            if (!_isInitialChatMessagesCountFetched) {
              _viewedDriverMessagesCount = currentDriverMessagesCount;
              _isInitialChatMessagesCountFetched = true;
            } else if (currentDriverMessagesCount >
                _viewedDriverMessagesCount) {
              _unreadChatMessagesCount =
                  currentDriverMessagesCount - _viewedDriverMessagesCount;
            }
          });
        }
      });
    } catch (_) {}
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (!_initialized) {
      _initialized = true;
      _routeDrawn = false;
      final passengerLat =
          LocationService.lastPosition?.latitude ?? widget.ride.pickupLat;
      final passengerLng =
          LocationService.lastPosition?.longitude ?? widget.ride.pickupLng;

      if (_locationSubscription != null) {
        unawaited(_locationSubscription!.cancel());
      }
      _locationSubscription = LocationService.getPositionStream().listen((
        pos,
      ) async {
        _liveMapBloc?.add(
          DispatchTelemetryLocationEvent(
            lat: pos.latitude,
            lng: pos.longitude,
            rideId: widget.ride.id,
          ),
        );
      }, onError: (_) {});

      unawaited(
        BlocProvider.of<TrackDriverCubit>(context).startTracking(
          startLat: passengerLat,
          startLng: passengerLng,
          endLat: passengerLat,
          endLng: passengerLng,
          rideId: widget.ride.id,
          driverId: widget.ride.driverId,
          driverName: widget.ride.driverName,
          vehiclePlate: widget.ride.vehiclePlate,
          vehicleType: widget.ride.vehicleType,
          destinationLat: widget.ride.destLat,
          destinationLng: widget.ride.destLng,
        ),
      );
    }
  }

  Future<void> _updateMapElements(
    double driverLat,
    double driverLng,
    List<List<double>>? routePoints,
    RideStatus status,
  ) async {
    if (_mapController == null) return;
    final passengerLat =
        LocationService.lastPosition?.latitude ?? widget.ride.pickupLat;
    final passengerLng =
        LocationService.lastPosition?.longitude ?? widget.ride.pickupLng;

    try {
      if (!_routeDrawn && routePoints != null && routePoints.isNotEmpty) {
        _routeDrawn = true;
        _routeLineManager = await MapProvider.addAnimatedPolyline(
          _mapController!,
          routePoints,
          color: AppTheme.primaryColor.withValues(alpha: 0.6),
          width: 5.0,
        );
      }

      if (_passengerMarkerManager != null) {
        await MapProvider.clearAnnotations(_passengerMarkerManager);
      }
      if (_driverMarkerManager != null) {
        await MapProvider.clearAnnotations(_driverMarkerManager);
      }
      if (_destinationMarkerManager != null) {
        await MapProvider.clearAnnotations(_destinationMarkerManager);
      }

      final isInTransit = status == RideStatus.inTransit;
      final primaryLat = isInTransit ? widget.ride.destLat : passengerLat;
      final primaryLng = isInTransit ? widget.ride.destLng : passengerLng;
      _passengerMarkerManager = await MapProvider.addMarker(
        _mapController!,
        primaryLat,
        primaryLng,
        isOrigin: true,
        label: isInTransit
            ? 'Destination\n${widget.ride.destination}'
            : 'Current location\nYou are here',
        color: const Color(0xFF222222),
      );
      _driverMarkerManager = await MapProvider.addMarker(
        _mapController!,
        driverLat,
        driverLng,
        isOrigin: false,
        label: 'Your driver\n${widget.ride.driverName}',
        color: const Color(0xFFE53935),
      );
      if (isInTransit) {
        _destinationMarkerManager = await MapProvider.addMarker(
          _mapController!,
          passengerLat,
          passengerLng,
          label: 'Passenger\nCurrent location',
          color: AppTheme.secondaryColor,
        );
      }

      await MapProvider.fitBounds(_mapController!, [
        LatLng(primaryLat, primaryLng),
        LatLng(driverLat, driverLng),
        if (isInTransit) LatLng(passengerLat, passengerLng),
      ], padding: 80.0);
    } catch (error) {
      debugPrint('Error updating track map: $error');
    }
  }

  Future _handleCancelTrip() async {
    await showDialog(
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
              unawaited(
                BlocProvider.of<TrackDriverCubit>(context).cancelTrip(),
              );
            },
            child: const Text(
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
    final passengerLat =
        LocationService.lastPosition?.latitude ?? widget.ride.pickupLat;
    final passengerLng =
        LocationService.lastPosition?.longitude ?? widget.ride.pickupLng;

    return BlocListener<TrackDriverCubit, TrackDriverState>(
      listener: (context, state) {
        if (state is TrackDriverInProgress) {
          if (_lastMapStatus != state.status) {
            _routeDrawn = false;
            _lastMapStatus = state.status;
            unawaited(MapProvider.clearAnnotations(_routeLineManager));
            _routeLineManager = null;
          }
          unawaited(
            _updateMapElements(
              state.driverLat,
              state.driverLng,
              state.routePoints,
              state.status,
            ),
          );
        } else if (state is TrackDriverCompleted) {
          unawaited(
            context.pushNamed(
              ActivityRoutes.passengerPayment,
              extra: widget.ride,
            ),
          );
        } else if (state is TrackDriverCanceled) {
          if (mounted) {
            context.goNamed(HomeRoutes.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppTheme.neutralColor,
                child: SizedBox.expand(
                  child: MapProvider.buildMapView(
                    latitude: passengerLat,
                    longitude: passengerLng,
                    zoom: 14.5,
                    interactive: true,
                    onMapCreated: _onMapCreated,
                  ),
                ),
              ),
            ),

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
                        context.goNamed(HomeRoutes.home);
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
                                state is TrackDriverInProgress &&
                                        state.status == RideStatus.inTransit
                                    ? 'TRIP TO'
                                    : 'ARRIVING IN',
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

            Align(
              alignment: Alignment.bottomCenter,
              child: BlocBuilder<TrackDriverCubit, TrackDriverState>(
                builder: (context, state) {
                  final isInTransit =
                      state is TrackDriverInProgress &&
                      state.status == RideStatus.inTransit;
                  final hasArrived =
                      state is TrackDriverInProgress &&
                      state.status == RideStatus.arrived;
                  final statusTitle = isInTransit
                      ? 'You are on the trip'
                      : hasArrived
                      ? 'Driver has arrived'
                      : state is TrackDriverInProgress
                      ? 'Driver En Route'
                      : 'Driver Assigned';
                  final statusSubtitle = isInTransit
                      ? 'Heading to ${widget.ride.destination}'
                      : hasArrived
                      ? 'Please meet your driver at pickup'
                      : state is TrackDriverInProgress
                      ? 'Heading towards pickup location'
                      : 'Preparing to head to pickup';
                  final etaText = state is TrackDriverInProgress
                      ? state.eta
                      : 'En Route';

                  return LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 600.0;
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 600.0 : double.infinity,
                        ),
                        child: TrackDriverPanelWidget(
                          ride: widget.ride,
                          statusTitle: statusTitle,
                          statusSubtitle: statusSubtitle,
                          etaText: etaText,
                          unreadChatMessagesCount: _unreadChatMessagesCount,
                          onCallDriverPressed: () async {
                            try {
                              final activeRideId =
                                  await Modular.get<SecureSessionService>()
                                      .readActiveRideId() ??
                                  widget.ride.id;
                              if (activeRideId.isNotEmpty) {
                                final driverProfile =
                                    await Modular.get<BiddingRemoteDataSource>()
                                        .fetchDriverStats(activeRideId);
                                final phone = driverProfile['phone'] as String?;

                                if (phone != null && phone.isNotEmpty) {
                                  final uri = Uri.parse('tel:$phone');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              }
                            } catch (_) {}
                          },
                          onChatDriverPressed: () async {
                            final passengerId =
                                await Modular.get<SecureSessionService>()
                                    .readPassengerId() ??
                                '';
                            final dName = state is TrackDriverInProgress
                                ? state.driverName
                                : (widget.ride.driverName.isNotEmpty
                                      ? widget.ride.driverName
                                      : 'Driver');
                            if (context.mounted) {
                              setState(() {
                                _unreadChatMessagesCount = 0;
                              });
                              await context.pushNamed(
                                ChatRoutes.driverChat,
                                extra: {
                                  'roomId': widget.ride.id,
                                  'userId': passengerId,
                                  'peerName': dName,
                                },
                              );
                              _isInitialChatMessagesCountFetched = false;
                              await _updateUnreadMessagesCount();
                            }
                          },
                          onCancelTripPressed: _handleCancelTrip,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

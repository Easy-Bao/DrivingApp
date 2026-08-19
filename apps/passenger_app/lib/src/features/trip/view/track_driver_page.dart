import 'dart:async';

import 'package:dio/dio.dart';
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
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_state.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/view/widgets/track_driver_panel_widget.dart';
import 'package:passenger_app/src/shared/widgets/app_back_button_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityTrackDriverPage extends StatefulWidget {
  final RideHistoryModel ride;

  const ActivityTrackDriverPage({super.key, required this.ride});

  @override
  State<ActivityTrackDriverPage> createState() =>
      _ActivityTrackDriverPageState();
}

class _ActivityTrackDriverPageState extends State<ActivityTrackDriverPage> {
  AppMapController? _mapController;
  bool _initialized = false;
  bool _routeDrawn = false;
  bool _hasFittedInitialMap = false;
  bool _isUpdatingMap = false;
  bool _hasHandledTerminalState = false;
  RideStatus? _lastMapStatus;
  dynamic _passengerMarkerManager;
  dynamic _driverMarkerManager;
  dynamic _routeLineManager;
  StreamSubscription<Position>? _locationSubscription;
  LiveMapBloc? _liveMapBloc;

  int _unreadChatMessagesCount = 0;
  int _viewedDriverMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;
  Timer? _chatMessagesPollTimer;
  ChatRepository? _chatRepository;
  bool _isCancellingTrip = false;
  bool _isPollingChat = false;

  @override
  void initState() {
    super.initState();
    _liveMapBloc = Modular.get<LiveMapBloc>();
    unawaited(_initializeChatRepository());
    _startChatMessagesPolling();
  }

  Future<void> _initializeChatRepository() async {
    final passengerIdentifier =
        await Modular.get<SecureSessionService>().readPassengerId() ?? '';
    if (!mounted || passengerIdentifier.isEmpty) return;
    _chatRepository = ChatRepository(
      remoteDataSource: WebSocketChatRemoteDataSource(),
      currentUserId: passengerIdentifier,
      clientDio: Modular.get<Dio>(),
    );
  }

  @override
  void dispose() {
    unawaited(_locationSubscription?.cancel());
    _chatMessagesPollTimer?.cancel();
    unawaited(_chatRepository?.dispose());
    unawaited(_liveMapBloc?.close());
    for (final manager in [
      _routeLineManager,
      _passengerMarkerManager,
      _driverMarkerManager,
    ]) {
      unawaited(MapProvider.clearAnnotations(manager));
    }
    super.dispose();
  }

  void _startChatMessagesPolling() {
    _chatMessagesPollTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) async {
      await _updateUnreadMessagesCount();
    });
    unawaited(_updateUnreadMessagesCount());
  }

  Future<void> _updateUnreadMessagesCount() async {
    if (_isPollingChat) return;
    _isPollingChat = true;
    try {
      final chatRepository = _chatRepository;
      final passengerIdentifier = chatRepository?.currentUserId ?? '';
      if (chatRepository == null || passengerIdentifier.isEmpty) return;

      final result = await chatRepository.fetchRoomMessages(widget.ride.id);

      result.fold((_) => null, (List<ChatMessage> messages) {
        final driverChatMessagesList = messages
            .where((m) => m.senderId != passengerIdentifier)
            .toList();
        final currentDriverMessagesCount = driverChatMessagesList.length;

        if (!mounted) return;
        if (!_isInitialChatMessagesCountFetched) {
          _viewedDriverMessagesCount = currentDriverMessagesCount;
          _isInitialChatMessagesCountFetched = true;
          return;
        }

        final unreadMessagesCount =
            (currentDriverMessagesCount - _viewedDriverMessagesCount)
                .clamp(0, currentDriverMessagesCount)
                .toInt();
        if (unreadMessagesCount != _unreadChatMessagesCount) {
          setState(() => _unreadChatMessagesCount = unreadMessagesCount);
        }
      });
    } catch (_) {
      // A later bounded refresh can recover from a transient chat failure.
    } finally {
      _isPollingChat = false;
    }
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
    final mapController = _mapController;
    if (mapController == null || _isUpdatingMap) return;
    _isUpdatingMap = true;
    final passengerLat =
        LocationService.lastPosition?.latitude ?? widget.ride.pickupLat;
    final passengerLng =
        LocationService.lastPosition?.longitude ?? widget.ride.pickupLng;

    try {
      if (!_routeDrawn && routePoints != null && routePoints.isNotEmpty) {
        _routeDrawn = true;
        _routeLineManager = await _upsertRoute(
          _routeLineManager,
          mapController,
          routePoints,
        );
      }

      final isInTransit = status == RideStatus.inTransit;
      final targetLat = isInTransit ? widget.ride.destLat : passengerLat;
      final targetLng = isInTransit ? widget.ride.destLng : passengerLng;
      _passengerMarkerManager = await _upsertMarker(
        _passengerMarkerManager,
        mapController,
        targetLat,
        targetLng,
        isOrigin: true,
        color: isInTransit ? AppTheme.accent : AppTheme.primaryColor,
      );
      _driverMarkerManager = await _upsertMarker(
        _driverMarkerManager,
        mapController,
        driverLat,
        driverLng,
        isOrigin: false,
        color: AppTheme.complete,
      );
      if (!_hasFittedInitialMap) {
        await MapProvider.fitBounds(
          mapController,
          [LatLng(targetLat, targetLng), LatLng(driverLat, driverLng)],
          padding: 72.0,
          maxZoom: 15.0,
        );
        _hasFittedInitialMap = true;
      }
    } catch (error) {
      debugPrint('Error updating track map: $error');
    } finally {
      _isUpdatingMap = false;
    }
  }

  Future<dynamic> _upsertMarker(
    dynamic annotationManager,
    AppMapController mapController,
    double lat,
    double lng, {
    required bool isOrigin,
    required Color color,
  }) async {
    if (annotationManager == null) {
      return MapProvider.addMarker(
        mapController,
        lat,
        lng,
        isOrigin: isOrigin,
        color: color,
      );
    }
    await MapProvider.replaceMarker(
      annotationManager,
      lat,
      lng,
      isOrigin: isOrigin,
      color: color,
    );
    return annotationManager;
  }

  Future<dynamic> _upsertRoute(
    dynamic annotationManager,
    AppMapController mapController,
    List<List<double>> routePoints,
  ) async {
    if (annotationManager == null) {
      return MapProvider.addPolyline(
        mapController,
        routePoints,
        color: AppTheme.primaryColor,
        width: 4.0,
      );
    }
    await MapProvider.replacePolyline(
      annotationManager,
      routePoints,
      color: AppTheme.primaryColor,
      width: 4.0,
    );
    return annotationManager;
  }

  Future<void> _handleCancelTrip() async {
    if (_isCancellingTrip) return;
    final shouldCancel = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(ctx, false),
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
              Navigator.pop(ctx, true);
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
    if (shouldCancel != true || !mounted) return;

    setState(() => _isCancellingTrip = true);
    try {
      await BlocProvider.of<TrackDriverCubit>(context).cancelTrip();
    } finally {
      if (mounted) setState(() => _isCancellingTrip = false);
    }
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
          if (_hasHandledTerminalState) return;
          _hasHandledTerminalState = true;
          Modular.get<BookingBloc>().add(const ResetBookingEvent());
          context.pushReplacementNamed(
            ActivityRoutes.passengerPayment,
            extra: widget.ride,
          );
        } else if (state is TrackDriverCanceled) {
          if (_hasHandledTerminalState) return;
          _hasHandledTerminalState = true;
          Modular.get<BookingBloc>().add(const ResetBookingEvent());
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
                    AppBackButtonWidget.plain(
                      onPressed: () => context.goNamed(HomeRoutes.home),
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
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: AppTheme.tertiaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state is TrackDriverInProgress &&
                                        state.status == RideStatus.inTransit
                                    ? 'TRIP TO'
                                    : 'ARRIVING IN',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.tertiaryColor,
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
              child: SafeArea(
                top: false,
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
                        ? hasArrived
                              ? 'Meet up'
                              : state.eta
                        : 'En Route';
                    final driverName = state is TrackDriverInProgress
                        ? state.driverName
                        : null;
                    final vehicleSummary = state is TrackDriverInProgress
                        ? [state.vehicleType, state.vehiclePlate]
                              .where((value) => value.trim().isNotEmpty)
                              .join(' • ')
                        : null;

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
                            driverName: driverName,
                            vehicleSummary: vehicleSummary,
                            unreadChatMessagesCount: _unreadChatMessagesCount,
                            isCancellingTrip: _isCancellingTrip,
                            onCallDriverPressed: () async {
                              try {
                                final activeRideId =
                                    await Modular.get<SecureSessionService>()
                                        .readActiveRideId() ??
                                    widget.ride.id;
                                if (activeRideId.isNotEmpty) {
                                  final driverProfile =
                                      await Modular.get<
                                            BiddingRemoteDataSource
                                          >()
                                          .fetchDriverStats(activeRideId);
                                  final phone =
                                      driverProfile['phone'] as String?;

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
                                  ? (state.driverName.isNotEmpty
                                        ? state.driverName
                                        : widget.ride.displayDriverName)
                                  : widget.ride.displayDriverName;
                              if (context.mounted) {
                                setState(() {
                                  _unreadChatMessagesCount = 0;
                                });
                                await context.pushNamed(
                                  ChatRoutes.driverChat,
                                  extra: {
                                    'roomId': widget.ride.id,
                                    'userId': passengerId,
                                    'peerId': widget.ride.driverId,
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
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 76,
              right: 16,
              child: MapZoomControlsWidget(
                onZoomIn: _mapController == null
                    ? null
                    : () => unawaited(MapProvider.zoomIn(_mapController!)),
                onZoomOut: _mapController == null
                    ? null
                    : () => unawaited(MapProvider.zoomOut(_mapController!)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

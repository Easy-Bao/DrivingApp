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
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

class _MapUpdateRequest {
  final double driverLat;
  final double driverLng;
  final List<List<double>>? routePoints;
  final RideStatus status;
  final String driverName;

  const _MapUpdateRequest({
    required this.driverLat,
    required this.driverLng,
    required this.routePoints,
    required this.status,
    required this.driverName,
  });
}

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
  bool _hasFittedInitialMap = false;
  bool _isUpdatingMap = false;
  _MapUpdateRequest? _pendingMapUpdate;
  bool _hasHandledTerminalState = false;
  DateTime? _lastCameraFitAt;
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
    unawaited(_updateUnreadMessagesCount());
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
          // Messages already in the room were not necessarily read by the
          // passenger. Start from zero so the chat action exposes them.
          _viewedDriverMessagesCount = 0;
          _isInitialChatMessagesCountFetched = true;
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
      final passengerLat = widget.ride.pickupLat;
      final passengerLng = widget.ride.pickupLng;

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
    String driverName,
  ) async {
    final mapController = _mapController;
    final request = _MapUpdateRequest(
      driverLat: driverLat,
      driverLng: driverLng,
      routePoints: routePoints,
      status: status,
      driverName: driverName,
    );
    if (mapController == null || _isUpdatingMap) {
      _pendingMapUpdate = request;
      return;
    }
    _isUpdatingMap = true;
    final passengerLat = widget.ride.pickupLat;
    final passengerLng = widget.ride.pickupLng;

    try {
      final isInTransit = status == RideStatus.inTransit;
      final targetLat = isInTransit ? widget.ride.destLat : passengerLat;
      final targetLng = isInTransit ? widget.ride.destLng : passengerLng;
      final validRoutePoints = routePoints
          ?.where(_isValidRoutePoint)
          .toList(growable: false);
      if (validRoutePoints != null && validRoutePoints.length >= 2) {
        _routeLineManager = await _upsertRoute(
          _routeLineManager,
          mapController,
          validRoutePoints,
        );
      } else if (_routeLineManager != null) {
        await MapProvider.clearAnnotations(_routeLineManager);
        _routeLineManager = null;
      }
      final startLat = isInTransit ? driverLat : passengerLat;
      final startLng = isInTransit ? driverLng : passengerLng;
      final endLat = isInTransit ? targetLat : driverLat;
      final endLng = isInTransit ? targetLng : driverLng;
      _passengerMarkerManager = await _upsertMarker(
        _passengerMarkerManager,
        mapController,
        startLat,
        startLng,
        isOrigin: true,
        color: isInTransit
            ? TripMapMarkerStyle.tripLocation
            : TripMapMarkerStyle.ownLocation,
        animate: isInTransit,
      );
      _driverMarkerManager = await _upsertMarker(
        _driverMarkerManager,
        mapController,
        endLat,
        endLng,
        isOrigin: false,
        color: TripMapMarkerStyle.tripLocation,
        animate: !isInTransit,
      );
      final now = DateTime.now();
      if (!_hasFittedInitialMap ||
          _lastCameraFitAt == null ||
          now.difference(_lastCameraFitAt!) >= const Duration(seconds: 8)) {
        await MapProvider.fitBounds(
          mapController,
          [LatLng(targetLat, targetLng), LatLng(driverLat, driverLng)],
          padding: 72.0,
          maxZoom: 15.0,
        );
        _hasFittedInitialMap = true;
        _lastCameraFitAt = now;
      }
    } catch (error) {
      debugPrint('Error updating track map: $error');
    } finally {
      _isUpdatingMap = false;
      final pending = _pendingMapUpdate;
      _pendingMapUpdate = null;
      if (pending != null && mounted) {
        unawaited(
          _updateMapElements(
            pending.driverLat,
            pending.driverLng,
            pending.routePoints,
            pending.status,
            pending.driverName,
          ),
        );
      }
    }
  }

  bool _isValidRoutePoint(List<double> point) {
    return point.length >= 2 &&
        point[0].isFinite &&
        point[1].isFinite &&
        point[0] >= -180 &&
        point[0] <= 180 &&
        point[1] >= -90 &&
        point[1] <= 90;
  }

  Future<dynamic> _upsertMarker(
    dynamic annotationManager,
    AppMapController mapController,
    double lat,
    double lng, {
    required bool isOrigin,
    required Color color,
    String? label,
    bool animate = false,
  }) async {
    if (annotationManager == null) {
      return MapProvider.addMarker(
        mapController,
        lat,
        lng,
        isOrigin: isOrigin,
        color: color,
        label: label,
      );
    }
    await MapProvider.replaceMarker(
      annotationManager,
      lat,
      lng,
      isOrigin: isOrigin,
      color: color,
      label: label,
      animate: animate,
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
    final passengerLat = widget.ride.pickupLat;
    final passengerLng = widget.ride.pickupLng;

    return BlocListener<TrackDriverCubit, TrackDriverState>(
      listener: (context, state) {
        if (state is TrackDriverInProgress) {
          unawaited(
            _updateMapElements(
              state.driverLat,
              state.driverLng,
              state.routePoints,
              state.status,
              state.driverName,
            ),
          );
        } else if (state is TrackDriverCompleted) {
          if (_hasHandledTerminalState) return;
          _hasHandledTerminalState = true;
          Modular.get<BookingBloc>().add(const ResetBookingEvent());
          context.pushReplacementNamed(
            ActivityRoutes.passengerPayment,
            extra: widget.ride.copyWith(
              driverId: state.driverId,
              driverName: state.driverName,
            ),
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
                    _buildTripBackButton(
                      context,
                      () => context.goNamed(HomeRoutes.home),
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
                        ? 'Heading To Your Destination'
                        : hasArrived
                        ? 'Driver Has Arrived'
                        : state is TrackDriverInProgress
                        ? 'Driver Is Picking You Up'
                        : 'Driver Assigned';
                    final statusSubtitle = isInTransit
                        ? 'Heading To ${widget.ride.destination}'
                        : hasArrived
                        ? 'Meet Your Driver At Pickup'
                        : state is TrackDriverInProgress
                        ? 'Your Driver Is On The Way To Pickup'
                        : 'Your Driver Is Preparing For Pickup';
                    final etaText = state is TrackDriverInProgress
                        ? hasArrived
                              ? 'Driver Arrived'
                              : isInTransit
                              ? 'To Drop Off'
                              : 'To Pickup'
                        : 'To Pickup';
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
                            showContactActions: !isInTransit,
                            isCancellingTrip: _isCancellingTrip,
                            onCallDriverPressed: () async {
                              try {
                                final rideId = widget.ride.id.trim();
                                if (rideId.isNotEmpty) {
                                  final driverProfile =
                                      await Modular.get<
                                            BiddingRemoteDataSource
                                          >()
                                          .getRideCounterparty(rideId);
                                  final phone = SafeParse.toStringValue(
                                    driverProfile['phone'],
                                  ).trim();

                                  if (phone.isNotEmpty) {
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
                                  _viewedDriverMessagesCount +=
                                      _unreadChatMessagesCount;
                                  _unreadChatMessagesCount = 0;
                                  _isInitialChatMessagesCountFetched = true;
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
          ],
        ),
      ),
    );
  }
}

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: AppTheme.surface,
      elevation: 2,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor),
          ),
        ),
      ),
    ),
  );
}

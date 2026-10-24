import 'dart:async';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/core/location/live_map_bloc.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/active_trip_exit_dialog.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_panel.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/trip_cancellation_dialog.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/home/home_routes.dart';

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: context.colorScheme.surface,
      elevation: 2,
      shadowColor: context.colorScheme.onSurface.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: 'Back',
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(
                LucideIcons.arrow_left,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class const TrackDriverPage({
  super.key,
  required this.ride,
  required this.trackRepository,
  required this.chatRepositoryFactory,
  required this.sessionService,
  required this.lifecycleCoordinator,
  required this.liveMapBloc,
  required this.onRideTerminated,
  this.realtimeClient,
}) extends StatefulWidget {
  final RideSnapshot ride;
  final TrackRepository trackRepository;
  final ChatRepositoryFactory chatRepositoryFactory;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final LiveMapBloc liveMapBloc;
  final VoidCallback onRideTerminated;
  final RealtimeWebSocketClient? realtimeClient;

  @override
  State<TrackDriverPage> createState() => _TrackDriverPageState();
}

class _MapUpdateRequest {
  const _MapUpdateRequest({
    required this.driverLatitude,
    required this.driverLongitude,
    required this.routeCoordinates,
    required this.status,
    required this.driverName,
  });

  final double driverLatitude;
  final double driverLongitude;
  final Float64List? routeCoordinates;
  final RideStatus status;
  final String driverName;
}

class _TrackDriverPageState extends State<TrackDriverPage> {
  AppMapController? _mapController;
  bool _initialized = false;
  bool _hasFittedInitialMap = false;
  bool _isUpdatingMap = false;
  _MapUpdateRequest? _pendingMapUpdate;
  bool _hasHandledTerminalState = false;
  DateTime? _lastCameraFitAt;
  MapPointAnnotationManager? _passengerMarkerManager;
  MapPointAnnotationManager? _driverMarkerManager;
  MapPolylineAnnotationManager? _routeLineManager;
  StreamSubscription<Position>? _locationSubscription;
  LiveMapBloc? _liveMapBloc;

  int _unreadChatMessagesCount = 0;
  DateTime? _chatReadAt;
  late final AppLifecyclePeriodicTask _chatMessagesPollingTask;
  ChatRepository? _chatRepository;
  String _passengerIdentifier = '';
  bool _isCancellingTrip = false;
  bool _isPollingChat = false;
  String? _errorMessage;
  StreamSubscription<RealtimeConnectionState>? _realtimeStateSubscription;
  bool _isTransportRetrying = false;

  @override
  Widget build(BuildContext context) {
    final passengerLat = widget.ride.pickupLatitude ?? 0.0;
    final passengerLng = widget.ride.pickupLongitude ?? 0.0;
    final isNetworkUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    final hasTopBanner =
        (_isTransportRetrying || _errorMessage != null) &&
        !isNetworkUnavailable;

    return BlocListener<TrackDriverCubit, TrackDriverState>(
      listener: (context, state) {
        switch (state) {
          case DriverEnRoute(
            :final driverLat,
            :final driverLng,
            :final routePoints,
            :final status,
            :final driverName,
          ):
            unawaited(
              _updateMapElements(
                driverLat,
                driverLng,
                routePoints?.toCoordinateBuffer(),
                status,
                driverName,
              ),
            );
          case TripInProgress(
            :final driverLat,
            :final driverLng,
            :final routePoints,
            :final status,
            :final driverName,
          ):
            unawaited(
              _updateMapElements(
                driverLat,
                driverLng,
                routePoints?.toCoordinateBuffer(),
                status,
                driverName,
              ),
            );
          case TripCompleted(:final driverId, :final driverName):
            if (_hasHandledTerminalState) return;
            _hasHandledTerminalState = true;
            widget.onRideTerminated();
            context.pushReplacementNamed(
              ActiveRideRoutes.tripCompletion,
              extra: widget.ride.copyWith(
                status: 'completed',
                driverId: driverId,
                driverName: driverName,
              ),
            );
          case RideFailed():
            if (_hasHandledTerminalState) return;
            _hasHandledTerminalState = true;
            widget.onRideTerminated();
            if (mounted) {
              context.goNamed(HomeRoutes.home);
            }
          case Idle() || SearchingDriver():
            return;
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          unawaited(_handleBackNavigation());
        },
        child: Scaffold(
          backgroundColor: context.colorScheme.surface,
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: context.colorScheme.surfaceContainerHighest,
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

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppStatusBanner(
                      isVisible: _isTransportRetrying && _errorMessage == null,
                      message:
                          'Reconnecting live updates. Trip tracking continues.',
                      tone: AppStatusBannerTone.warning,
                    ),
                    if (_errorMessage != null)
                      AppStatusBanner(
                        isVisible: true,
                        message: _errorMessage!,
                        tone: AppStatusBannerTone.error,
                        actionLabel: 'Dismiss',
                        onAction: () => setState(() => _errorMessage = null),
                      ),
                    SafeArea(
                      top: !hasTopBanner,
                      bottom: false,
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
                              () => unawaited(_handleBackNavigation()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: BlocBuilder<TrackDriverCubit, TrackDriverState>(
                    builder: (context, state) {
                      final isInTransit = state.isInTransit;
                      final hasArrived = state.hasArrived;
                      final statusTitle = isInTransit
                          ? 'On your trip'
                          : hasArrived
                          ? 'Meet your driver'
                          : 'Driver is on the way';
                      final statusSubtitle = isInTransit
                          ? widget.ride.dropoffName
                          : widget.ride.pickupName;
                      final etaText = switch (state) {
                        DriverEnRoute(:final eta) when !hasArrived => eta,
                        TripInProgress(:final eta) => eta,
                        _ => '',
                      };
                      final driverName = state.isTracking
                          ? state.activeDriverName
                          : null;
                      final vehicleSummary = state.isTracking
                          ? [state.activeVehicleType, state.activeVehiclePlate]
                                .where((value) => value.trim().isNotEmpty)
                                .join(' • ')
                          : null;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 600.0;
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWide ? 600.0 : double.infinity,
                              maxHeight: constraints.maxHeight * 0.65,
                            ),
                            child: SingleChildScrollView(
                              child: TrackDriverPanel(
                                ride: widget.ride,
                                statusTitle: statusTitle,
                                statusSubtitle: statusSubtitle,
                                etaText: etaText,
                                driverName: driverName,
                                vehicleSummary: vehicleSummary,
                                driverRating: widget.ride.displayDriverRating,
                                unreadChatMessagesCount:
                                    _unreadChatMessagesCount,
                                showContactActions: true,
                                isCancellingTrip: _isCancellingTrip,
                                isInTransit: isInTransit,
                                onChatDriverPressed: () async {
                                  final passengerId =
                                      await widget.sessionService
                                          .readPassengerId() ??
                                      '';
                                  final peerDriverName =
                                      state.activeDriverName.isNotEmpty
                                      ? state.activeDriverName
                                      : widget.ride.displayDriverName;
                                  if (context.mounted) {
                                    await _markChatMessagesRead();
                                    if (!context.mounted) return;
                                    await context.pushNamed(
                                      ChatRoutes.driverChat,
                                      extra: {
                                        'roomId': widget.ride.id,
                                        'userId': passengerId,
                                        'peerId': widget.ride.driverId ?? '',
                                        'peerName': peerDriverName,
                                      },
                                    );
                                    await _updateUnreadMessagesCount();
                                  }
                                },
                                onReportDriverPressed: () =>
                                    unawaited(_handleReportDriverPressed()),
                                onCancelTripPressed: _handleCancelTrip,
                              ),
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
      ),
    );
  }

  @override
  void dispose() {
    widget.realtimeClient?.setActiveTripResyncHandler(null);
    unawaited(_realtimeStateSubscription?.cancel());
    unawaited(_locationSubscription?.cancel());
    unawaited(_chatMessagesPollingTask.dispose());
    unawaited(_chatRepository?.dispose());
    unawaited(_liveMapBloc?.close());
    for (final manager in <MapBaseAnnotationManager?>[
      _routeLineManager,
      _passengerMarkerManager,
      _driverMarkerManager,
    ]) {
      unawaited(MapProvider.clearAnnotations(manager));
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _liveMapBloc = widget.liveMapBloc;
    widget.realtimeClient?.setActiveTripResyncHandler(_resyncActiveTrip);
    _realtimeStateSubscription = widget.realtimeClient?.states.listen((state) {
      if (!mounted) return;
      final retrying =
          state is RealtimeDisconnected || state is RealtimeConnecting;
      if (_isTransportRetrying != retrying) {
        setState(() => _isTransportRetrying = retrying);
      }
    });
    _chatMessagesPollingTask = AppLifecyclePeriodicTask(
      lifecycleCoordinator: widget.lifecycleCoordinator,
      interval: const Duration(seconds: 4),
      onTick: _updateUnreadMessagesCount,
      runImmediately: true,
    );
    unawaited(_initializeChatRepository());
    _chatMessagesPollingTask.start();
  }

  Future<void> _cancelTripRequest({required String reason}) async {
    if (_isCancellingTrip || !mounted) return;

    setState(() => _isCancellingTrip = true);
    try {
      final canceled = await BlocProvider.of<TrackDriverCubit>(context)
          .cancelTripRequest(reason: reason);
      if (mounted && !canceled) {
        setState(() => _errorMessage = "Couldn't cancel the ride. Try again.");
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = "Couldn't cancel the ride. Try again.");
      }
    } finally {
      if (mounted) setState(() => _isCancellingTrip = false);
    }
  }

  void _flushPendingMapUpdate() {
    if (_mapController == null || _isUpdatingMap || !mounted) return;
    final pending = _pendingMapUpdate;
    if (pending == null) return;
    _pendingMapUpdate = null;
    unawaited(
      _updateMapElements(
        pending.driverLatitude,
        pending.driverLongitude,
        pending.routeCoordinates,
        pending.status,
        pending.driverName,
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    final cubit = BlocProvider.of<TrackDriverCubit>(context);
    if (!cubit.state.isTracking) {
      if (mounted) context.goNamed(HomeRoutes.home);
      return;
    }

    final driverName = cubit.state.activeDriverName.isNotEmpty
        ? cubit.state.activeDriverName
        : widget.ride.displayDriverName;

    final action = await showDialog<ActiveTripExitAction>(
      context: context,
      builder: (_) => ActiveTripExitDialog(driverName: driverName),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case ActiveTripExitAction.keepTracking:
        return;
      case ActiveTripExitAction.cancel:
        await _handleCancelTrip();
      case ActiveTripExitAction.minimize:
        context.goNamed(HomeRoutes.home);
    }
  }

  Future<void> _handleCancelTrip() async {
    if (_isCancellingTrip) return;
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const TripCancellationDialog(),
    );
    if (reason == null || !mounted) return;

    await _cancelTripRequest(reason: reason);
  }

  Future<void> _handleReportDriverPressed() async {
    final state = BlocProvider.of<TrackDriverCubit>(context).state;
    await showSafetyReportSheet(
      context,
      rideId: widget.ride.id,
      driverName: state.activeDriverName.isNotEmpty
          ? state.activeDriverName
          : widget.ride.displayDriverName,
      vehiclePlate: state.activeVehiclePlate.isNotEmpty
          ? state.activeVehiclePlate
          : widget.ride.plateNumber ?? '',
      vehicleType: state.activeVehicleType.isNotEmpty
          ? state.activeVehicleType
          : widget.ride.vehicleType ?? '',
      trackRepository: widget.trackRepository,
    );
  }

  Future<void> _initializeChatRepository() async {
    final passengerIdentifier =
        await widget.sessionService.readPassengerId() ?? '';
    if (!mounted || passengerIdentifier.isEmpty) return;
    _passengerIdentifier = passengerIdentifier;
    _chatReadAt = await widget.sessionService.readChatReadAt(widget.ride.id);
    _chatRepository = widget.chatRepositoryFactory.create(
      currentUserId: passengerIdentifier,
    );
    unawaited(_updateUnreadMessagesCount());
  }

  Future<void> _markChatMessagesRead() async {
    final chatRepository = _chatRepository;
    if (chatRepository == null) return;

    var readAt = DateTime.now().toUtc();
    final result = await chatRepository.fetchRoomMessages(widget.ride.id);
    result.fold((_) {}, (messages) {
      for (final message in messages) {
        if (message.senderId == _passengerIdentifier) continue;
        final createdAt = message.createdAt.toUtc();
        if (createdAt.isAfter(readAt)) readAt = createdAt;
      }
    });
    _chatReadAt = readAt;
    await widget.sessionService.saveChatReadAt(widget.ride.id, readAt);
    if (!mounted) return;
    setState(() => _unreadChatMessagesCount = 0);
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    _flushPendingMapUpdate();
    if (!_initialized) {
      _initialized = true;
      final passengerLat = widget.ride.pickupLatitude ?? 0.0;
      final passengerLng = widget.ride.pickupLongitude ?? 0.0;

      if (_locationSubscription != null) {
        unawaited(_locationSubscription!.cancel());
      }
      final trackDriverCubit = BlocProvider.of<TrackDriverCubit>(context);
      _locationSubscription = LocationService.getPositionStream().listen((
        position,
      ) {
        unawaited(
          trackDriverCubit.publishPassengerLocation(
            rideId: widget.ride.id,
            latitude: position.latitude,
            longitude: position.longitude,
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
          driverId: widget.ride.driverId ?? '',
          driverName: widget.ride.driverName ?? '',
          vehiclePlate: widget.ride.plateNumber ?? '',
          vehicleType: widget.ride.vehicleType ?? '',
          destinationLat: widget.ride.dropoffLatitude ?? 0.0,
          destinationLng: widget.ride.dropoffLongitude ?? 0.0,
        ),
      );
    }
  }

  Future<void> _resyncActiveTrip() async {
    if (!mounted) return;
    await BlocProvider.of<TrackDriverCubit>(context).resyncActiveTrip();
  }

  Future<void> _updateMapElements(
    double driverLatitude,
    double driverLongitude,
    Float64List? routeCoordinates,
    RideStatus status,
    String driverName,
  ) async {
    final mapController = _mapController;
    final request = _MapUpdateRequest(
      driverLatitude: driverLatitude,
      driverLongitude: driverLongitude,
      routeCoordinates: routeCoordinates,
      status: status,
      driverName: driverName,
    );
    if (mapController == null || _isUpdatingMap) {
      _pendingMapUpdate = request;
      return;
    }
    _isUpdatingMap = true;
    final passengerLatitude = widget.ride.pickupLatitude ?? 0.0;
    final passengerLongitude = widget.ride.pickupLongitude ?? 0.0;

    try {
      final isInTransit = status == RideStatus.inTransit;
      final targetLatitude = isInTransit
          ? (widget.ride.dropoffLatitude ?? 0.0)
          : passengerLatitude;
      final targetLongitude = isInTransit
          ? (widget.ride.dropoffLongitude ?? 0.0)
          : passengerLongitude;
      if (routeCoordinates != null && routeCoordinates.length >= 4) {
        _routeLineManager = await _upsertRoute(
          _routeLineManager,
          mapController,
          routeCoordinates,
        );
      } else if (_routeLineManager != null) {
        await MapProvider.clearAnnotations(_routeLineManager);
        _routeLineManager = null;
      }
      final destinationLatitude = isInTransit
          ? targetLatitude
          : passengerLatitude;
      final destinationLongitude = isInTransit
          ? targetLongitude
          : passengerLongitude;
      _passengerMarkerManager = await _upsertMarker(
        _passengerMarkerManager,
        mapController,
        destinationLatitude,
        destinationLongitude,
        isOrigin: true,
        color: isInTransit
            ? TripMapMarkerStyle.tripLocation
            : TripMapMarkerStyle.ownLocation,
        animate: false,
      );
      _driverMarkerManager = await _upsertMarker(
        _driverMarkerManager,
        mapController,
        driverLatitude,
        driverLongitude,
        isOrigin: false,
        color: TripMapMarkerStyle.tripLocation,
        animate: true,
      );
      final now = DateTime.now();
      if (!_hasFittedInitialMap ||
          _lastCameraFitAt == null ||
          now.difference(_lastCameraFitAt!) >= const Duration(seconds: 8)) {
        await MapProvider.fitBounds(
          mapController,
          [
            LatLng(targetLatitude, targetLongitude),
            LatLng(driverLatitude, driverLongitude),
          ],
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
      _flushPendingMapUpdate();
    }
  }

  Future<void> _updateUnreadMessagesCount() async {
    if (_isPollingChat) return;
    _isPollingChat = true;
    try {
      final chatRepository = _chatRepository;
      final passengerIdentifier = _passengerIdentifier;
      if (chatRepository == null || passengerIdentifier.isEmpty) return;

      final result = await chatRepository.fetchRoomMessages(widget.ride.id);

      result.fold((_) => null, (List<ChatMessage> messages) {
        final driverChatMessagesList = messages
            .where((m) => m.senderId != passengerIdentifier)
            .toList();
        if (!mounted) return;
        final readAt = _chatReadAt;
        final unreadMessagesCount = driverChatMessagesList
            .where(
              (message) =>
                  readAt == null || message.createdAt.toUtc().isAfter(readAt),
            )
            .length;
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

  Future<MapPointAnnotationManager> _upsertMarker(
    MapPointAnnotationManager? annotationManager,
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

  Future<MapPolylineAnnotationManager?> _upsertRoute(
    MapPolylineAnnotationManager? annotationManager,
    AppMapController mapController,
    Float64List routeCoordinates,
  ) async {
    if (!mounted) return annotationManager;
    final color = context.colorScheme.onSurface;
    if (annotationManager == null) {
      return MapProvider.addPolylineBuffer(
        mapController,
        routeCoordinates,
        color: color,
        width: 4.0,
      );
    }
    await MapProvider.replacePolylineBuffer(
      annotationManager,
      routeCoordinates,
      color: color,
      width: 4.0,
    );
    return annotationManager;
  }
}

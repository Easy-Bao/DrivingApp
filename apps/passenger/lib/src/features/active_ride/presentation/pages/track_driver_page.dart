import 'dart:async';

import 'package:chat/chat.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/active_trip_exit_dialog.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/safety_report_sheet.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_chat_tracker.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_map_controller.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_panel.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/trip_cancellation_dialog.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';

class const TrackDriverPage({
  super.key,
  required this.ride,
  required this.trackRepository,
  required this.chatRepositoryFactory,
  required this.sessionService,
  required this.lifecycleCoordinator,
  required this.onRideTerminated,
  this.realtimeClient,
}) extends StatefulWidget {
  final RideSnapshot ride;
  final TrackRepository trackRepository;
  final ChatRepositoryFactory chatRepositoryFactory;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final VoidCallback onRideTerminated;
  final RealtimeWebSocketClient? realtimeClient;

  @override
  State<TrackDriverPage> createState() => _TrackDriverPageState();
}

class _TrackDriverPageState extends State<TrackDriverPage> {
  final _panelKey = GlobalKey();
  late final TrackDriverCubit _trackDriverCubit;
  late final TrackDriverMapController _mapController;
  late final TrackDriverChatTracker _chatTracker;

  Widget? _cachedMapView;
  StreamSubscription<Position>? _locationSubscription;
  bool _initialized = false;
  bool _hasHandledTerminalState = false;
  bool _isCancellingTrip = false;

  @override
  void initState() {
    super.initState();
    _trackDriverCubit = BlocProvider.of<TrackDriverCubit>(context);
    widget.realtimeClient?.setActiveTripResyncHandler(
      _trackDriverCubit.resyncActiveTrip,
    );
    _mapController = TrackDriverMapController(
      pickupLatitude: widget.ride.pickupLatitude ?? 0.0,
      pickupLongitude: widget.ride.pickupLongitude ?? 0.0,
      dropoffLatitude: widget.ride.dropoffLatitude ?? 0.0,
      dropoffLongitude: widget.ride.dropoffLongitude ?? 0.0,
      resolveRouteColor: () => context.colorScheme.onSurface,
      resolveViewportPadding: () => EdgeInsets.fromLTRB(
        40,
        MediaQuery.paddingOf(context).top + 72,
        40,
        (_panelKey.currentContext?.size?.height ?? 320) +
            MediaQuery.paddingOf(context).bottom +
            32,
      ),
      isMounted: () => mounted,
    );
    _chatTracker = TrackDriverChatTracker(
      rideId: widget.ride.id,
      chatRepositoryFactory: widget.chatRepositoryFactory,
      sessionService: widget.sessionService,
      lifecycleCoordinator: widget.lifecycleCoordinator,
    )..start();
  }

  @override
  void dispose() {
    if (_hasHandledTerminalState || !_trackDriverCubit.state.isTracking) {
      widget.realtimeClient?.setActiveTripResyncHandler(null);
    }
    unawaited(_locationSubscription?.cancel());
    _chatTracker.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(AppMapController controller) {
    _mapController.onMapCreated(controller);
    _startTracking();
  }

  void _startTracking() {
    if (_initialized) return;
    _initialized = true;
    final passengerLat = widget.ride.pickupLatitude ?? 0.0;
    final passengerLng = widget.ride.pickupLongitude ?? 0.0;

    if (_locationSubscription case final subscription?) {
      unawaited(subscription.cancel());
    }
    _locationSubscription = LocationService.getPositionStream().listen((
      position,
    ) {
      unawaited(
        _trackDriverCubit.publishPassengerLocation(
          rideId: widget.ride.id,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    }, onError: (_) {});

    unawaited(
      _trackDriverCubit.startTracking(
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

  bool _shouldListenForMapOrTerminal(
    TrackDriverState previous,
    TrackDriverState current,
  ) {
    if (current.isTerminal) return true;
    if (!current.isTracking) return false;
    return previous.driverLatitude != current.driverLatitude ||
        previous.driverLongitude != current.driverLongitude ||
        previous.trackingStatus != current.trackingStatus ||
        !identical(previous.activeRoutePoints, current.activeRoutePoints);
  }

  bool _shouldRebuildPanel(
    TrackDriverState previous,
    TrackDriverState current,
  ) {
    return previous.isTracking != current.isTracking ||
        previous.isInTransit != current.isInTransit ||
        previous.hasArrived != current.hasArrived ||
        previous.trackingEta != current.trackingEta ||
        previous.activeDriverName != current.activeDriverName ||
        previous.activeVehicleType != current.activeVehicleType ||
        previous.activeVehiclePlate != current.activeVehiclePlate;
  }

  void _handleTrackState(BuildContext context, TrackDriverState state) {
    switch (state) {
      case DriverEnRoute(
            :final driverLat,
            :final driverLng,
            :final routePoints,
            :final status,
          ) ||
          TripInProgress(
            :final driverLat,
            :final driverLng,
            :final routePoints,
            :final status,
          ):
        unawaited(
          _mapController.update(
            TrackDriverMapUpdate(
              driverLatitude: driverLat,
              driverLongitude: driverLng,
              routePoints: routePoints,
              status: status,
            ),
          ),
        );
      case TripCompleted(:final driverId, :final driverName):
        if (_hasHandledTerminalState) return;
        _hasHandledTerminalState = true;
        widget.realtimeClient?.setActiveTripResyncHandler(null);
        widget.onRideTerminated();
        context.pushReplacementNamed(
          RideHistoryRoutes.tripCompletion,
          extra: widget.ride.copyWith(
            status: 'completed',
            driverId: driverId,
            driverName: driverName,
          ),
        );
      case RideFailed(:final message):
        if (_hasHandledTerminalState) return;
        _hasHandledTerminalState = true;
        widget.realtimeClient?.setActiveTripResyncHandler(null);
        widget.onRideTerminated();
        if (mounted) {
          final notice = message.trim().isEmpty
              ? 'This trip is no longer active.'
              : message.trim();
          AppSnackBar.show(context, notice, isError: true);
          context.goNamed(HomeRoutes.home);
        }
      case Idle() || SearchingDriver():
        return;
    }
  }

  Future<void> _openChat(TrackDriverState state) async {
    final passengerId = await widget.sessionService.readPassengerId() ?? '';
    if (!mounted) return;
    final peerDriverName = state.activeDriverName.isNotEmpty
        ? state.activeDriverName
        : widget.ride.displayDriverName;
    await _chatTracker.markMessagesRead();
    if (!mounted) return;
    await context.pushNamed(
      ChatRoutes.driverChat,
      extra: {
        'roomId': widget.ride.id,
        'userId': passengerId,
        'peerId': widget.ride.driverId ?? '',
        'peerName': peerDriverName,
      },
    );
    if (!mounted) return;
    await _chatTracker.markMessagesRead();
    await _chatTracker.refreshUnreadCount();
  }

  Future<void> _cancelTripRequest({required String reason}) async {
    if (_isCancellingTrip || !mounted) return;

    setState(() => _isCancellingTrip = true);
    try {
      final canceled = await _trackDriverCubit.cancelTripRequest(
        reason: reason,
      );
      if (mounted && !canceled) {
        AppSnackBar.show(
          context,
          "Couldn't cancel the ride. Try again.",
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          "Couldn't cancel the ride. Try again.",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isCancellingTrip = false);
    }
  }

  Future<void> _handleBackNavigation() async {
    if (!_trackDriverCubit.state.isTracking) {
      if (mounted) context.goNamed(HomeRoutes.home);
      return;
    }

    final driverName = _trackDriverCubit.state.activeDriverName.isNotEmpty
        ? _trackDriverCubit.state.activeDriverName
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
    final reason = await showTripCancellationSheet(context);
    if (reason == null || !mounted) return;
    await _cancelTripRequest(reason: reason);
  }

  Future<void> _handleReportDriverPressed() async {
    final state = _trackDriverCubit.state;
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

  @override
  Widget build(BuildContext context) {
    final passengerLat = widget.ride.pickupLatitude ?? 0.0;
    final passengerLng = widget.ride.pickupLongitude ?? 0.0;

    return BlocListener<TrackDriverCubit, TrackDriverState>(
      listenWhen: _shouldListenForMapOrTerminal,
      listener: _handleTrackState,
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
                    child: _cachedMapView ??= MapProvider.buildMapView(
                      latitude: passengerLat,
                      longitude: passengerLng,
                      zoom: 14.5,
                      interactive: true,
                      onMapCreated: _onMapCreated,
                      onMapLoaded: _mapController.onMapReady,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: true,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppMapBackButton(
                        onPressed: () => unawaited(_handleBackNavigation()),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: BlocBuilder<TrackDriverCubit, TrackDriverState>(
                    buildWhen: _shouldRebuildPanel,
                    builder: (context, state) {
                      final isInTransit = state.isInTransit;
                      final hasArrived = state.hasArrived;
                      final statusTitle = !state.isTracking
                          ? 'Updating trip status…'
                          : isInTransit
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
                              key: _panelKey,
                              child: ValueListenableBuilder<int>(
                                valueListenable: _chatTracker.unreadCount,
                                builder: (_, unreadCount, _) =>
                                    TrackDriverPanel(
                                      ride: widget.ride,
                                      statusTitle: statusTitle,
                                      statusSubtitle: statusSubtitle,
                                      etaText: etaText,
                                      driverName: driverName,
                                      vehicleSummary: vehicleSummary,
                                      driverRating:
                                          widget.ride.displayDriverRating,
                                      unreadChatMessagesCount: unreadCount,
                                      showContactActions: true,
                                      isCancellingTrip: _isCancellingTrip,
                                      isInTransit: isInTransit,
                                      onChatDriverPressed: () =>
                                          _openChat(state),
                                      onReportDriverPressed: () => unawaited(
                                        _handleReportDriverPressed(),
                                      ),
                                      onCancelTripPressed: _handleCancelTrip,
                                    ),
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
}

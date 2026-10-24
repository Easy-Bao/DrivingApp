import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_ride_cancellation_sheet.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_trip_panel.dart';
import 'package:driver/src/features/chat/chat.dart';
import 'package:driver/src/features/chat/chat_routes.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class const DriverTripPage({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.duration,
  required this.chatRepositoryFactory,
  required this.sessionService,
  required this.lifecycleCoordinator,
}) extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;
  final ChatRepositoryFactory chatRepositoryFactory;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;

  @override
  State<DriverTripPage> createState() => _DriverTripPageState();
}

class _DriverTripPageState extends State<DriverTripPage> {
  late final LiveMapBloc _liveMapBloc;
  late final RideFlowCubit _rideCubit;
  late final AppLifecyclePeriodicTask _trackingTask;
  ChatRepository? _chatRepository;
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;
  Widget? _map;
  double _progress = 0;
  bool _isActing = false;
  bool _isRefreshing = false;
  bool _paymentOpened = false;
  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;

  @override
  void initState() {
    super.initState();
    _rideCubit = BlocProvider.of<RideFlowCubit>(context);
    _liveMapBloc = BlocProvider.of<LiveMapBloc>(context);
    _pickupLatitude = _rideCubit.state.pickupLatitude;
    _pickupLongitude = _rideCubit.state.pickupLongitude;
    _destinationLatitude = _rideCubit.state.destinationLatitude;
    _destinationLongitude = _rideCubit.state.destinationLongitude;
    unawaited(WakelockPlus.enable());
    _trackingTask = AppLifecyclePeriodicTask(
      lifecycleCoordinator: widget.lifecycleCoordinator,
      interval: const Duration(seconds: 4),
      onTick: _refreshTracking,
      runImmediatelyOnResume: true,
    );
    _trackingTask.start();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final driverId = await widget.sessionService.readDriverId() ?? '';
    if (!mounted) return;
    if (driverId.isNotEmpty) {
      _chatRepository = widget.chatRepositoryFactory.create(
        currentUserId: driverId,
      );
    }
    try {
      if (_pickupLatitude == null && _rideCubit.state is! TripInProgress) {
        final places = await MapProvider.searchPlaces(widget.pickup);
        if (!mounted) return;
        if (places.isNotEmpty) {
          _pickupLatitude = places.first.latitude;
          _pickupLongitude = places.first.longitude;
        }
      }
      if (_destinationLatitude == null) {
        final places = await MapProvider.searchPlaces(widget.dropoff);
        if (!mounted) return;
        if (places.isNotEmpty) {
          _destinationLatitude = places.first.latitude;
          _destinationLongitude = places.first.longitude;
        }
      }
      if (mounted) setState(() {});
      await _refreshTracking();
    } catch (_) {
      // The periodic refresh keeps the trip usable after a transient map failure.
    }
  }

  Future<void> _refreshTracking() async {
    if (!mounted || _isRefreshing || _paymentOpened) return;
    _isRefreshing = true;
    try {
      await _updateUnreadMessagesCount(_rideCubit);
      if (!mounted) return;
      if (_rideCubit.state is TripInProgress) {
        await _rideCubit.refreshPassengerLocation();
      }
      if (!mounted) return;
      final position =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (!mounted || position == null) return;
      _liveMapBloc.add(
        DispatchTelemetryLocationEvent(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
      _drawRoute(position.latitude, position.longitude);
    } catch (_) {
      // A later foreground refresh can recover without replacing the trip screen.
    } finally {
      _isRefreshing = false;
    }
  }

  void _drawRoute(double latitude, double longitude) {
    final state = _rideCubit.state;
    final inTransit = state is TripInProgress;
    final targetLat = inTransit
        ? state.destinationLatitude ?? _destinationLatitude
        : state.pickupLatitude ?? _pickupLatitude;
    final targetLng = inTransit
        ? state.destinationLongitude ?? _destinationLongitude
        : state.pickupLongitude ?? _pickupLongitude;
    if (targetLat == null || targetLng == null) return;
    _liveMapBloc.add(
      UpdateLocationsAndDrawRouteEvent(
        driverLatitude: latitude,
        driverLongitude: longitude,
        passengerLatitude: inTransit ? state.passengerLatitude : targetLat,
        passengerLongitude: inTransit ? state.passengerLongitude : targetLng,
        routeTargetLatitude: inTransit ? targetLat : null,
        routeTargetLongitude: inTransit ? targetLng : null,
      ),
    );
  }

  void _onMapCreated(
    AppMapController controller,
    double latitude,
    double longitude,
  ) {
    _liveMapBloc.add(
      InitializeMapEvent(
        controller: controller,
        defaultLatitude: latitude,
        defaultLongitude: longitude,
        routeColor: context.colorScheme.primary,
      ),
    );
    _drawRoute(latitude, longitude);
  }

  void _onRideChanged(BuildContext context, RideState state) {
    if (state is TripCompleted) {
      _openPayment(state.fare);
      return;
    }
    final position = LocationService.lastPosition;
    if (position != null && state is! RideFailed) {
      _drawRoute(position.latitude, position.longitude);
    }
  }

  void _openPayment(double fare) {
    if (!mounted || _paymentOpened) return;
    _paymentOpened = true;
    context.pushReplacementNamed(
      ActiveRideRoutes.fareSummary,
      extra: {
        'rideId': _rideCubit.activeRideId,
        'bookingReference': _rideCubit.activeBookingReference,
        'pickup': widget.pickup,
        'dropoff': widget.dropoff,
        'distance': widget.distance,
        'fare': fare,
        'duration': widget.duration,
      },
    );
  }

  void _showError(String message) {
    if (mounted) AppSnackBar.show(context, message, isError: true);
  }

  Future<void> _advance() async {
    if (_isActing) return;
    setState(() => _isActing = true);
    try {
      final state = _rideCubit.state;
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position == null) {
        _showError(
          'Your location is unavailable. Enable location and try again.',
        );
        return;
      }
      if (state is TripInProgress) {
        final fare = await _rideCubit.completeRide(
          driverLatitude: position.latitude,
          driverLongitude: position.longitude,
        );
        if (!mounted) return;
        if (fare != null) {
          _openPayment(fare);
          return;
        }
      } else if (state.isWaitingAtPickup) {
        final started = await _rideCubit.startRide(
          passengerName: state.passengerNameOr('Passenger'),
          destinationLatitude:
              state.destinationLatitude ?? _destinationLatitude,
          destinationLongitude:
              state.destinationLongitude ?? _destinationLongitude,
          distanceKm: widget.distance,
          driverLatitude: position.latitude,
          driverLongitude: position.longitude,
          observedAt: position.timestamp,
          passengerLatitude: state.pickupLatitude ?? _pickupLatitude,
          passengerLongitude: state.pickupLongitude ?? _pickupLongitude,
        );
        if (!mounted || started) return;
      } else if (state is DriverEnRoute) {
        final latitude = state.pickupLatitude ?? _pickupLatitude;
        final longitude = state.pickupLongitude ?? _pickupLongitude;
        if (latitude == null || longitude == null) {
          _showError(
            'Pickup location is unavailable. Reopen the trip and try again.',
          );
          return;
        }
        await _rideCubit.arriveAtPickup(
          state.passengerName,
          driverLatitude: position.latitude,
          driverLongitude: position.longitude,
          observedAt: position.timestamp,
          pickupLatitude: latitude,
          pickupLongitude: longitude,
          destinationLatitude:
              state.destinationLatitude ?? _destinationLatitude,
          destinationLongitude:
              state.destinationLongitude ?? _destinationLongitude,
        );
        if (!mounted || _rideCubit.state.isWaitingAtPickup) return;
      } else {
        return;
      }
      _showError(
        _rideCubit.lastActionFailureMessage ??
            _rideCubit.state.failureMessage ??
            'The trip could not be updated. Please try again.',
      );
    } catch (error) {
      _showError(ErrorHandler.getErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isActing = false;
          _progress = 0;
        });
      }
    }
  }

  Future<void> _markNoShow() async {
    if (_isActing ||
        !_rideCubit.state.isWaitingAtPickup ||
        !_rideCubit.canMarkPassengerNoShow) {
      return;
    }
    setState(() => _isActing = true);
    try {
      final marked = await _rideCubit.markPassengerNoShow();
      if (!mounted) return;
      if (marked) {
        context.pop();
        return;
      }
      _showError(
        _rideCubit.state.failureMessage ??
            'Unable to record the passenger no-show. Please try again.',
      );
    } catch (error) {
      _showError(ErrorHandler.getErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _openChat() async {
    final driverId = await widget.sessionService.readDriverId() ?? '';
    final rideId = _rideCubit.activeRideId;
    if (!mounted || driverId.isEmpty || rideId == null) return;
    setState(() {
      _viewedPassengerMessagesCount += _unreadChatMessagesCount;
      _unreadChatMessagesCount = 0;
      _isInitialChatMessagesCountFetched = true;
    });
    await context.pushNamed(
      ChatRoutes.chat,
      extra: {
        'roomId': rideId,
        'userId': driverId,
        'peerId': _rideCubit.activePassengerId,
        'peerName': _rideCubit.activePassengerName,
      },
    );
    if (mounted) await _updateUnreadMessagesCount(_rideCubit);
  }

  Future<void> _updateUnreadMessagesCount(RideFlowCubit cubit) async {
    if (!widget.lifecycleCoordinator.isForeground) return;
    try {
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      final driverIdentifier = await widget.sessionService.readDriverId() ?? '';
      if (driverIdentifier.isEmpty) return;

      final chatRepository = _chatRepository;
      if (chatRepository == null) return;
      final result = await chatRepository.fetchRoomMessages(rideId);
      result.fold((_) => null, (List<ChatMessage> messages) {
        final passengerChatMessagesList = messages
            .where((m) => m.senderId != driverIdentifier)
            .toList();
        final currentPassengerMessagesCount = passengerChatMessagesList.length;

        if (!_isInitialChatMessagesCountFetched) {
          _viewedPassengerMessagesCount = 0;
          _isInitialChatMessagesCountFetched = true;
        }
        final unreadCount =
            (currentPassengerMessagesCount - _viewedPassengerMessagesCount)
                .clamp(0, currentPassengerMessagesCount)
                .toInt();
        if (mounted && unreadCount != _unreadChatMessagesCount) {
          setState(() => _unreadChatMessagesCount = unreadCount);
        }
      });
    } catch (_) {}
  }

  Future<void> _cancelRide() async {
    if (_isActing || !mounted) return;
    final choice = await showRideCancellationSheet(context);
    if (!mounted || choice == null) return;

    setState(() => _isActing = true);
    try {
      final canceled = await BlocProvider.of<RideFlowCubit>(context)
          .cancelRide(reason: choice.reason, details: choice.details);
      if (!mounted) return;
      if (canceled) {
        context.pop();
      } else {
        _showError(
          BlocProvider.of<RideFlowCubit>(context).state.failureMessage ??
              'The ride could not be cancelled. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  void dispose() {
    unawaited(_trackingTask.dispose());
    unawaited(_chatRepository?.dispose());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RideFlowCubit, RideState>(
      buildWhen: (_, current) =>
          current is DriverEnRoute || current is TripInProgress,
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: _onRideChanged,
      builder: (context, state) {
        final position = LocationService.lastPosition;
        final latitude =
            position?.latitude ??
            state.pickupLatitude ??
            _pickupLatitude ??
            state.destinationLatitude ??
            _destinationLatitude;
        final longitude =
            position?.longitude ??
            state.pickupLongitude ??
            _pickupLongitude ??
            state.destinationLongitude ??
            _destinationLongitude;
        if (_map == null && latitude != null && longitude != null) {
          _map = MapProvider.buildMapView(
            latitude: latitude,
            longitude: longitude,
            zoom: 15,
            onMapCreated: (controller) =>
                _onMapCreated(controller, latitude, longitude),
          );
        }
        return PopScope(
          canPop: false,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child:
                      _map ??
                      const Center(child: Text('Map location is unavailable.')),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: IconButton.filledTonal(
                      tooltip: 'Back to dashboard',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) => ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 600,
                          maxHeight: constraints.maxHeight * 0.72,
                        ),
                        child: SingleChildScrollView(
                          child: DriverTripPanel(
                            state: state,
                            pickup: widget.pickup,
                            dropoff: widget.dropoff,
                            fare: widget.fare,
                            progress: _progress,
                            isBusy: _isActing,
                            unreadCount: _unreadChatMessagesCount,
                            onProgressChanged: (value) =>
                                setState(() => _progress = value),
                            onAdvance: _advance,
                            onChat: _openChat,
                            onCancel: _cancelRide,
                            noShowRemaining:
                                _rideCubit.passengerNoShowTimeRemaining,
                            onNoShow: _rideCubit.canMarkPassengerNoShow
                                ? _markNoShow
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:chat/chat.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/features/active_ride/domain/repositories/ride_repository.dart';
import 'package:driver/src/features/active_ride/domain/services/ride_completion_handler.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/controllers/driver_trip_chat_tracker.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_trip_panel.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_cancellation_sheet.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/safety_report_sheet.dart';
import 'package:driver/src/features/chat/chat_routes.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class const DriverTripPage({
  super.key,
  this.rideId,
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.chatRepositoryFactory,
  required this.sessionService,
  required this.lifecycleCoordinator,
  required this.rideCompletionHandler,
  this.rideRepository,
}) extends StatefulWidget {
  final String? rideId;
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final ChatRepositoryFactory chatRepositoryFactory;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final RideCompletionHandler rideCompletionHandler;
  final RideRepository? rideRepository;

  @override
  State<DriverTripPage> createState() => _DriverTripPageState();
}

class _DriverTripPageState extends State<DriverTripPage> {
  late final LiveMapBloc _liveMapBloc;
  late final RideFlowCubit _rideCubit;
  late final AppLifecyclePeriodicTask _trackingTask;
  late final DriverTripChatTracker _chatTracker;
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0);
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;
  final _panelKey = GlobalKey();
  Widget? _map;
  AppMapController? _mapController;
  DriverTripBusyAction _busyAction = DriverTripBusyAction.none;
  String? _notice;
  bool _isRefreshing = false;
  bool _tripFinished = false;
  bool _isFinishingCompletion = false;
  double? _completedFare;
  String? _completedRideId;
  String? _completedPassengerName;
  bool _safetyReportSubmitted = false;
  bool _completionHapticPlayed = false;

  bool get _isActing => _busyAction != DriverTripBusyAction.none;

  bool get _isShowingCompletionSummary =>
      _completedFare != null || _rideCubit.state is TripCompleted;

  @override
  void initState() {
    super.initState();
    _rideCubit = BlocProvider.of<RideFlowCubit>(context);
    _liveMapBloc = BlocProvider.of<LiveMapBloc>(context);
    _chatTracker = DriverTripChatTracker(
      chatRepositoryFactory: widget.chatRepositoryFactory,
      sessionService: widget.sessionService,
      lifecycleCoordinator: widget.lifecycleCoordinator,
    );
    _pickupLatitude = _rideCubit.state.pickupLatitude;
    _pickupLongitude = _rideCubit.state.pickupLongitude;
    _destinationLatitude = _rideCubit.state.destinationLatitude;
    _destinationLongitude = _rideCubit.state.destinationLongitude;
    _ensureMap(_rideCubit.state);
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

  void _ensureMap(RideState state) {
    if (_map != null) return;
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
    if (latitude == null || longitude == null) return;
    _map = MapProvider.buildMapView(
      latitude: latitude,
      longitude: longitude,
      zoom: 15,
      onMapCreated: (controller) => _mapController = controller,
      onMapLoaded: () {
        final controller = _mapController;
        if (mounted && controller != null) {
          _onMapCreated(controller, latitude, longitude);
        }
      },
    );
  }

  Future<void> _initialize() async {
    await _chatTracker.initialize();
    if (!mounted) return;
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
      final hadMap = _map != null;
      _ensureMap(_rideCubit.state);
      if (mounted && !hadMap && _map != null) {
        setState(() {});
      }
      await _refreshTracking();
    } catch (_) {
      // The periodic refresh keeps the trip usable after a transient map failure.
    }
  }

  Future<void> _refreshTracking() async {
    if (!mounted ||
        _isRefreshing ||
        _tripFinished ||
        _isShowingCompletionSummary) {
      return;
    }
    _isRefreshing = true;
    try {
      await _chatTracker.refreshUnreadCount(_rideCubit.activeRideId);
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
        viewportPadding: EdgeInsets.fromLTRB(
          40,
          MediaQuery.paddingOf(context).top + 72,
          40,
          (_panelKey.currentContext?.size?.height ?? 360) +
              MediaQuery.paddingOf(context).bottom +
              32,
        ),
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
    if (_map == null) {
      _ensureMap(state);
      if (mounted && _map != null) setState(() {});
    }
    if (state is TripCompleted) {
      _enterCompletionSummary(
        fare: state.fare,
        passengerName:
            _completedPassengerName ?? _rideCubit.activePassengerName,
      );
      return;
    }
    if (state is RideFlowTerminal) {
      unawaited(_finishTrip());
      return;
    }
    if (state.isWaitingAtPickup) {
      unawaited(HapticFeedback.mediumImpact());
    } else if (state is TripInProgress) {
      unawaited(HapticFeedback.lightImpact());
    }
    final position = LocationService.lastPosition;
    if (position != null && state is! RideFailed) {
      _drawRoute(position.latitude, position.longitude);
    }
  }

  void _enterCompletionSummary({
    required double fare,
    required String passengerName,
  }) {
    if (!mounted) return;
    if (!_completionHapticPlayed) {
      _completionHapticPlayed = true;
      unawaited(HapticFeedback.mediumImpact());
    }
    setState(() {
      _completedFare = fare > 0 ? fare : widget.fare;
      _completedRideId ??= _rideCubit.activeRideId ?? widget.rideId;
      _completedPassengerName = passengerName;
      _notice = null;
    });
  }

  Future<void> _finishTrip() async {
    if (!mounted || _tripFinished) return;
    _tripFinished = true;
    if (_isShowingCompletionSummary && mounted) {
      setState(() => _isFinishingCompletion = true);
    }
    final rideId = _completedRideId ?? _rideCubit.activeRideId ?? widget.rideId;
    await _rideCubit.reset();
    if (rideId != null && rideId.isNotEmpty) {
      await widget.rideCompletionHandler.afterRideCompleted(rideId: rideId);
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(DashboardRoutes.dashboard);
    }
  }

  Future<void> _reportCompletedTripIssue() async {
    final rideRepository = widget.rideRepository;
    final rideId = _completedRideId ?? _rideCubit.activeRideId ?? widget.rideId;
    if (rideRepository == null || rideId == null || rideId.isEmpty) return;
    final reported = await showSafetyReportSheet(
      context,
      rideId: rideId,
      rideRepository: rideRepository,
    );
    if (reported && mounted) {
      setState(() => _safetyReportSubmitted = true);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  Future<void> _advance() async {
    if (_isActing) return;
    if (_rideCubit.state is RideFlowTerminal) {
      await _finishTrip();
      return;
    }
    setState(() => _busyAction = DriverTripBusyAction.advancing);
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
        final passengerName = state.passengerNameOr(
          _rideCubit.activePassengerName,
        );
        final fare = await _rideCubit.completeRide(
          driverLatitude: position.latitude,
          driverLongitude: position.longitude,
        );
        if (!mounted) return;
        if (fare != null) {
          _enterCompletionSummary(fare: fare, passengerName: passengerName);
          return;
        }
        if (_rideCubit.state is RideFlowTerminal ||
            _rideCubit.activeRideId == null) {
          await _finishTrip();
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
      final failureMsg =
          _rideCubit.lastActionFailureMessage ??
          _rideCubit.state.failureMessage;
      if (failureMsg != null &&
          (failureMsg.toLowerCase().contains('completed') ||
              failureMsg.toLowerCase().contains('no longer active'))) {
        await _finishTrip();
        return;
      }
      _showError(
        failureMsg ?? 'The trip could not be updated. Please try again.',
      );
    } catch (error) {
      _showError(ErrorHandler.getErrorMessage(error));
    } finally {
      _progressNotifier.value = 0;
      if (mounted) {
        setState(() => _busyAction = DriverTripBusyAction.none);
      }
    }
  }

  Future<void> _markNoShow() async {
    if (_isActing ||
        !_rideCubit.state.isWaitingAtPickup ||
        !_rideCubit.canMarkPassengerNoShow) {
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Record passenger no-show?',
      message: 'This will end the trip because the passenger did not arrive at pickup.',
      confirmLabel: 'Confirm no-show',
      cancelLabel: 'Keep waiting',
      icon: LucideIcons.user_x,
      tone: AppConfirmDialogTone.warning,
      isDestructive: true,
    );
    if (!confirmed ||
        !mounted ||
        !_rideCubit.state.isWaitingAtPickup ||
        !_rideCubit.canMarkPassengerNoShow) {
      return;
    }
    setState(() => _busyAction = DriverTripBusyAction.markingNoShow);
    try {
      final marked = await _rideCubit.markPassengerNoShow();
      if (!mounted) return;
      if (marked) {
        AppSnackBar.show(
          context,
          'Passenger no-show recorded.',
          tone: AppSnackBarTone.info,
        );
        await _finishTrip();
        return;
      }
      _showError(
        _rideCubit.lastActionFailureMessage ??
            _rideCubit.state.failureMessage ??
            'Unable to record the passenger no-show. Please try again.',
      );
    } catch (error) {
      _showError(ErrorHandler.getErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busyAction = DriverTripBusyAction.none);
    }
  }

  Future<void> _openChat() async {
    final driverId = await _chatTracker.resolveDriverId();
    final rideId = _rideCubit.activeRideId;
    if (!mounted || driverId.isEmpty || rideId == null) return;
    _chatTracker.markCurrentUnreadViewed();
    await context.pushNamed(
      ChatRoutes.chat,
      extra: {
        'roomId': rideId,
        'userId': driverId,
        'peerId': _rideCubit.activePassengerId,
        'peerName': _rideCubit.activePassengerName,
      },
    );
    if (mounted) {
      await _chatTracker.refreshUnreadCount(
        _rideCubit.activeRideId,
        markAllViewed: true,
      );
    }
  }

  Future<void> _cancelRide() async {
    if (_isActing || !mounted) return;
    final choice = await showRideCancellationSheet(
      context,
      onSubmit: (selection) async {
        if (!mounted) return null;
        setState(() => _busyAction = DriverTripBusyAction.canceling);
        try {
          final canceled = await _rideCubit.cancelRide(
            reason: selection.reason,
            details: selection.details,
          );
          if (canceled) return null;
          return _rideCubit.lastActionFailureMessage ??
              _rideCubit.state.failureMessage ??
              'The ride could not be canceled. Please try again.';
        } catch (error) {
          return ErrorHandler.getErrorMessage(error);
        } finally {
          if (mounted) {
            setState(() => _busyAction = DriverTripBusyAction.none);
          }
        }
      },
    );
    if (!mounted || choice == null) return;
    AppSnackBar.show(context, 'Ride canceled.', tone: AppSnackBarTone.info);
    await _finishTrip();
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    unawaited(_trackingTask.dispose());
    unawaited(_chatTracker.dispose());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  Widget _buildCompletionSummary(BuildContext context, double completedFare) {
    final colors = context.colorScheme;
    final textStyles = context.textStyles;
    final passengerName =
        _completedPassengerName ?? _rideCubit.activePassengerName;
    final completedRideId =
        _completedRideId ?? _rideCubit.activeRideId ?? widget.rideId;
    final canReport =
        widget.rideRepository != null &&
        completedRideId != null &&
        completedRideId.isNotEmpty &&
        !_safetyReportSubmitted;

    return Scaffold(
      backgroundColor: context.canvasColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppCompletionView(
                key: const ValueKey<String>('driver-trip-completion-view'),
                title: 'Trip completed',
                message:
                    'Collect cash from $passengerName before heading to your next trip.',
                primaryActionLabel: _isFinishingCompletion
                    ? 'Returning…'
                    : 'Back to dispatch',
                onPrimaryAction: _isFinishingCompletion
                    ? null
                    : () => unawaited(_finishTrip()),
                secondaryActionLabel: canReport ? 'Report an issue' : null,
                onSecondaryAction: canReport
                    ? () => unawaited(_reportCompletedTripIssue())
                    : null,
                footnote: _safetyReportSubmitted
                    ? 'Safety report submitted.'
                    : null,
                summary: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CASH FARE TO COLLECT',
                        textAlign: TextAlign.center,
                        style: textStyles.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formatPesoAmount(completedFare),
                        textAlign: TextAlign.center,
                        style: textStyles.headlineMedium?.tabular.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.outlineVariant.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CompactRouteTimeline(
                        pickup: widget.pickup,
                        dropoff: widget.dropoff,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.outlineVariant.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Text(
                            'Passenger',
                            style: textStyles.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              passengerName,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.titleSmall?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideFlowCubit, RideState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: _onRideChanged,
      child: BlocBuilder<RideFlowCubit, RideState>(
        buildWhen: (previous, current) =>
            (previous is TripCompleted) != (current is TripCompleted),
        builder: (context, rideState) {
          final completedFare = rideState is TripCompleted
              ? (rideState.fare > 0 ? rideState.fare : widget.fare)
              : _completedFare;
          if (completedFare != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && !_isFinishingCompletion) {
                  unawaited(_finishTrip());
                }
              },
              child: _buildCompletionSummary(context, completedFare),
            );
          }

          return PopScope(
            canPop: !_isActing,
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child:
                        _map ??
                        const Center(
                          child: Text('Map location is unavailable.'),
                        ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Material(
                        color: context.colorScheme.surfaceContainerLowest,
                        shape: CircleBorder(
                          side: BorderSide(
                            color: context.colorScheme.outlineVariant,
                          ),
                        ),
                        elevation: 1,
                        shadowColor: context.colorScheme.shadow,
                        child: IconButton(
                          key: const ValueKey<String>('driver-trip-back'),
                          tooltip: 'Back to dashboard',
                          onPressed: _isActing ? null : () => context.pop(),
                          style:
                              IconButton.styleFrom(
                                foregroundColor: context.colorScheme.onSurface,
                                shape: const CircleBorder(),
                                enableFeedback: false,
                                splashFactory: NoSplash.splashFactory,
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.focused)) {
                                    return context.colorScheme.primary
                                        .withValues(alpha: 0.12);
                                  }
                                  return Colors.transparent;
                                }),
                              ),
                          icon: const Icon(LucideIcons.arrow_left, size: 20),
                        ),
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
                            key: _panelKey,
                            child: BlocBuilder<RideFlowCubit, RideState>(
                              buildWhen: (_, current) =>
                                  current is DriverEnRoute ||
                                  current is TripInProgress,
                              builder: (context, state) {
                                return ValueListenableBuilder<int>(
                                  valueListenable: _chatTracker.unreadCount,
                                  builder: (context, unreadCount, _) =>
                                      DriverTripPanel(
                                        state: state,
                                        pickup: widget.pickup,
                                        dropoff: widget.dropoff,
                                        fare: widget.fare,
                                        progress: _progressNotifier.value,
                                        progressListenable: _progressNotifier,
                                        isBusy: _isActing,
                                        busyAction: _busyAction,
                                        unreadCount: unreadCount,
                                        notice: _notice,
                                        onDismissNotice: () =>
                                            setState(() => _notice = null),
                                        onProgressChanged: (value) {
                                          _progressNotifier.value = value;
                                          if (value > 0 && _notice != null) {
                                            setState(() => _notice = null);
                                          }
                                        },
                                        onAdvance: _advance,
                                        onChat: _openChat,
                                        onCancel: _cancelRide,
                                        noShowRemaining: _rideCubit
                                            .passengerNoShowTimeRemaining,
                                        onNoShow:
                                            _rideCubit.canMarkPassengerNoShow
                                            ? _markNoShow
                                            : null,
                                      ),
                                );
                              },
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
      ),
    );
  }
}

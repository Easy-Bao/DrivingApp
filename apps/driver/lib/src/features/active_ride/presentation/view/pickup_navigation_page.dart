import 'package:driver/src/features/chat/chat.dart';
import 'package:maps/maps.dart';

import 'dart:async';

import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/chat/chat_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/pickup_navigation_panel.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_active_ride_header.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_safety_report_sheet.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_emergency_button.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_ride_cancellation_sheet.dart';
import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class const PickupNavigationPage({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.duration,
  required this.rideRepository,
  required this.chatRepositoryFactory,
  required this.sessionService,
  required this.lifecycleCoordinator,
  this.liveMapBloc,
}) extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;
  final RideRepository rideRepository;
  final ChatRepositoryFactory chatRepositoryFactory;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final LiveMapBloc? liveMapBloc;

  @override
  State<PickupNavigationPage> createState() => _PickupNavigationPageState();
}

class _PickupNavigationPageState extends State<PickupNavigationPage> {
  double _sliderProgress = 0;
  bool _isLoading = true;
  bool _isConfirmingArrival = false;
  bool _isCancellingRide = false;
  double? _pickupLatitude;
  double? _pickupLongitude;
  late final AppLifecyclePeriodicTask _routeTrackingTask;
  late final LiveMapBloc _liveMapBloc;
  bool _isRefreshingRoute = false;

  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;
  ChatRepository? _chatRepository;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    _liveMapBloc = widget.liveMapBloc ?? BlocProvider.of<LiveMapBloc>(context);
    final cubit = BlocProvider.of<RideFlowCubit>(context);
    _routeTrackingTask = AppLifecyclePeriodicTask(
      lifecycleCoordinator: widget.lifecycleCoordinator,
      interval: const Duration(seconds: 4),
      onTick: () => _refreshRoute(cubit),
      runImmediatelyOnResume: true,
    );
    unawaited(_initializeChatRepository());
    unawaited(_loadRoute());
  }

  Future<void> _initializeChatRepository() async {
    final driverIdentifier = await widget.sessionService.readDriverId() ?? '';
    if (!mounted || driverIdentifier.isEmpty) return;
    _chatRepository = widget.chatRepositoryFactory.create(
      currentUserId: driverIdentifier,
    );
    final cubit = BlocProvider.of<RideFlowCubit>(context);
    unawaited(_updateUnreadMessagesCount(cubit));
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable());
    unawaited(_routeTrackingTask.dispose());
    unawaited(_chatRepository?.dispose());
    super.dispose();
  }

  void _startRouteTracking() {
    _routeTrackingTask.start();
  }

  Future<void> _refreshRoute(RideFlowCubit cubit) async {
    if (!mounted || _isRefreshingRoute) return;
    _isRefreshingRoute = true;

    try {
      await _updateUnreadMessagesCount(cubit);
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      try {
        final position =
            LocationService.lastPosition ??
            await LocationService.getCurrentPosition();
        if (position != null) {
          if (mounted) {
            _liveMapBloc.add(
              DispatchTelemetryLocationEvent(
                latitude: position.latitude,
                longitude: position.longitude,
              ),
            );
          }
          if (mounted && _pickupLatitude != null && _pickupLongitude != null) {
            _liveMapBloc.add(
              UpdateLocationsAndDrawRouteEvent(
                driverLatitude: position.latitude,
                driverLongitude: position.longitude,
                passengerLatitude: _pickupLatitude!,
                passengerLongitude: _pickupLongitude!,
              ),
            );
          }
        }
      } catch (_) {}
    } finally {
      _isRefreshingRoute = false;
    }
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

  Future<void> _loadRoute() async {
    try {
      // Resolve the fixed pickup point before asking for the driver's current
      // position. A location permission delay must not leave the map blank or
      // prevent the route from being drawn once telemetry becomes available.
      final rideState = BlocProvider.of<RideFlowCubit>(context).state;
      final pickupLatitude = rideState.pickupLatitude;
      final pickupLongitude = rideState.pickupLongitude;
      if (pickupLatitude != null && pickupLongitude != null) {
        _pickupLatitude = pickupLatitude;
        _pickupLongitude = pickupLongitude;
      } else {
        final places = await MapProvider.searchPlaces(widget.pickup);
        if (places.isNotEmpty) {
          _pickupLatitude = places.first.latitude;
          _pickupLongitude = places.first.longitude;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      final position =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position != null) {
        _triggerDrawRoute(position.latitude, position.longitude);
      }
      _startRouteTracking();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Unable to load pickup route: $error\n$stackTrace');
    }
  }

  void _triggerDrawRoute(double driverLatitude, double driverLongitude) {
    final pickupLatitude = _pickupLatitude;
    final pickupLongitude = _pickupLongitude;
    if (pickupLatitude == null || pickupLongitude == null) return;
    _liveMapBloc.add(
      UpdateLocationsAndDrawRouteEvent(
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
        passengerLatitude: pickupLatitude,
        passengerLongitude: pickupLongitude,
      ),
    );
  }

  void _onMapCreated(AppMapController controller) {
    final position = LocationService.lastPosition;
    final defaultLatitude = position?.latitude ?? _pickupLatitude;
    final defaultLongitude = position?.longitude ?? _pickupLongitude;
    if (defaultLatitude == null || defaultLongitude == null) return;

    _liveMapBloc.add(
      InitializeMapEvent(
        controller: controller,
        defaultLatitude: defaultLatitude,
        defaultLongitude: defaultLongitude,
        routeColor: context.colorScheme.primary,
      ),
    );

    if (!_isLoading) {
      _triggerDrawRoute(defaultLatitude, defaultLongitude);
    }
  }

  Future<void> _confirmArrival(BuildContext context) async {
    if (_isConfirmingArrival) return;
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state.passengerNameOr('Passenger');
    final pickupLatitude = state.pickupLatitude ?? _pickupLatitude;
    final pickupLongitude = state.pickupLongitude ?? _pickupLongitude;
    if (pickupLatitude == null || pickupLongitude == null) return;

    setState(() => _isConfirmingArrival = true);
    final rideCubit = BlocProvider.of<RideFlowCubit>(context);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position == null) {
        CustomToast.show(
          this.context,
          'Your current location is unavailable. Enable location and try again.',
          isError: true,
        );
        return;
      }
      await rideCubit.arriveAtPickup(
        passengerName,
        driverLatitude: position.latitude,
        driverLongitude: position.longitude,
        observedAt: position.timestamp,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        destinationLatitude: state.destinationLatitude,
        destinationLongitude: state.destinationLongitude,
      );
      if (!mounted) return;
      if (!rideCubit.state.isWaitingAtPickup) {
        CustomToast.show(
          this.context,
          rideCubit.state.failureMessage ??
              'Unable to confirm arrival. Please try again.',
          isError: true,
        );
        return;
      }
      this.context.pushReplacementNamed(
        ActiveRideRoutes.waitingPassenger,
        extra: {
          'pickup': widget.pickup,
          'dropoff': widget.dropoff,
          'distance': widget.distance,
          'fare': widget.fare,
          'duration': widget.duration,
        },
      );
    } catch (error) {
      if (mounted) {
        CustomToast.show(
          this.context,
          rideCubit.state.failureMessage ?? ErrorHandler.getErrorMessage(error),
          isError: true,
        );
      }
      debugPrint('Unable to confirm driver arrival: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingArrival = false;
          _sliderProgress = 0;
        });
      }
    }
  }

  Future<void> _cancelRide() async {
    if (_isCancellingRide || !mounted) return;
    final choice = await showRideCancellationSheet(context);
    if (!mounted || choice == null) return;

    setState(() => _isCancellingRide = true);
    try {
      final canceled = await BlocProvider.of<RideFlowCubit>(context)
          .cancelRide(reason: choice.reason, details: choice.details);
      if (!mounted) return;
      if (canceled) {
        context.pop();
      } else {
        final failureMessage = BlocProvider.of<RideFlowCubit>(context)
            .state
            .failureMessage;
        CustomToast.show(
          context,
          failureMessage ??
              'The ride could not be cancelled. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isCancellingRide = false);
    }
  }

  Future<bool> _emergencyStop(String reason, String details) async {
    if (!mounted) return false;
    final stopped = await BlocProvider.of<RideFlowCubit>(context)
        .emergencyStop(reason: reason, details: details);
    if (!stopped && mounted) {
      final failureMessage = BlocProvider.of<RideFlowCubit>(context)
          .state
          .failureMessage;
      CustomToast.show(
        context,
        failureMessage ??
            'The ride could not be ended for safety. Please try again.',
        isError: true,
      );
    }
    return stopped;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveMapBloc>.value(
      value: _liveMapBloc,
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final position = LocationService.lastPosition;
          final defaultLatitude =
              position?.latitude ?? rideCubitState.pickupLatitude;
          final defaultLongitude =
              position?.longitude ?? rideCubitState.pickupLongitude;
          if (defaultLatitude == null || defaultLongitude == null) {
            return const PopScope(
              canPop: false,
              child: Scaffold(
                body: Center(child: Text('Pickup location is unavailable.')),
              ),
            );
          }

          return PopScope(
            canPop: false,
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: SizedBox.expand(
                      child: MapProvider.buildMapView(
                        latitude: defaultLatitude,
                        longitude: defaultLongitude,
                        zoom: 15.0,
                        onMapCreated: _onMapCreated,
                      ),
                    ),
                  ),
                  SafeArea(child: _buildHeader(context)),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (layoutContext, constraints) {
                          final isWide = constraints.maxWidth > 600.0;
                          final rideState = BlocProvider.of<RideFlowCubit>(
                            context,
                          ).state;
                          final passengerName = rideState.passengerNameOr(
                            'Passenger',
                          );

                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWide ? 600.0 : double.infinity,
                            ),
                            child: PickupNavigationPanel(
                              pickup: widget.pickup,
                              dropoff: widget.dropoff,
                              passengerName: passengerName,
                              distance: widget.distance,
                              fare: widget.fare,
                              sliderValue: _sliderProgress,
                              isConfirmingArrival: _isConfirmingArrival,
                              isCancelling: _isCancellingRide,
                              unreadChatMessagesCount: _unreadChatMessagesCount,
                              onSliderChanged: (progress) {
                                setState(() {
                                  _sliderProgress = progress;
                                });
                              },
                              onSliderCompleted: () => _confirmArrival(context),
                              onCancelPressed: _cancelRide,
                              onCallPressed: () async {
                                try {
                                  final rideCubit =
                                      BlocProvider.of<RideFlowCubit>(context);
                                  final rideId = rideCubit.activeRideId ?? '';
                                  if (rideId.isNotEmpty) {
                                    String? phone;
                                    (await widget.rideRepository
                                            .fetchCounterpartyResult(rideId))
                                        .fold(
                                          (_) {},
                                          (passenger) =>
                                              phone = passenger.phone,
                                        );
                                    final passengerPhone = phone;
                                    if (passengerPhone != null &&
                                        passengerPhone.isNotEmpty) {
                                      final uri = Uri.parse(
                                        'tel:$passengerPhone',
                                      );
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    }
                                  }
                                } catch (_) {}
                              },
                              onChatPressed: () async {
                                final rideId =
                                    BlocProvider.of<RideFlowCubit>(context)
                                        .activeRideId ??
                                    '';
                                final state = BlocProvider.of<RideFlowCubit>(
                                  context,
                                ).state;
                                final pName = state.passengerNameOr(
                                  'Passenger',
                                );
                                final driverId =
                                    await widget.sessionService
                                        .readDriverId() ??
                                    '';
                                if (!context.mounted) return;
                                setState(() {
                                  _viewedPassengerMessagesCount +=
                                      _unreadChatMessagesCount;
                                  _unreadChatMessagesCount = 0;
                                  _isInitialChatMessagesCountFetched = true;
                                });
                                await context.pushNamed(
                                  ChatRoutes.chat,
                                  extra: {
                                    'roomId': rideId,
                                    'userId': driverId,
                                    'peerId': BlocProvider.of<RideFlowCubit>(
                                      context,
                                    ).activePassengerId,
                                    'peerName': pName,
                                  },
                                );
                                if (!context.mounted) return;
                                await _updateUnreadMessagesCount(
                                  BlocProvider.of<RideFlowCubit>(context),
                                );
                              },
                            ),
                          );
                        },
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

  Widget _buildHeader(BuildContext context) {
    return ActiveRideHeader(
      rideId: BlocProvider.of<RideFlowCubit>(context).activeRideId,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      backButton: _buildTripBackButton(context, () => context.pop()),
      actions: [
        EmergencyButton(
          onEmergencyStop: _emergencyStop,
          onEmergencyStopCompleted: () {
            if (mounted) context.goNamed(DashboardRoutes.dashboard);
          },
        ),
        SafetyReportButton(
          rideId: BlocProvider.of<RideFlowCubit>(context).activeRideId,
          rideRepository: widget.rideRepository,
        ),
      ],
    );
  }
}

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: context.colorScheme.surface,
      elevation: 2,
      shadowColor: context.colorScheme.onSurface.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AppSize.minimumTouchTarget,
          height: AppSize.minimumTouchTarget,
          child: Center(
            child: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:maps/maps.dart';

import 'dart:async';

import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/chat/chat_routes.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_driver_ride_repository.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/pickup_navigation_panel_widget.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class PickupNavigationPage extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;
  final IDriverRideRepository rideRepository;
  final IChatRepositoryFactory chatRepositoryFactory;
  final SecureSessionService sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;

  const PickupNavigationPage({
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
  });

  @override
  State<PickupNavigationPage> createState() => _PickupNavigationPageState();
}

class _PickupNavigationPageState extends State<PickupNavigationPage> {
  double _sliderVal = 0;
  bool _isLoading = true;
  bool _isConfirmingArrival = false;
  double? _pickupLat;
  double? _pickupLng;
  late final AppLifecyclePeriodicTask _routeTrackingTask;
  late final LiveMapBloc _liveMapBloc;
  bool _isRefreshingRoute = false;

  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;
  IChatRepository? _chatRepository;

  @override
  void initState() {
    super.initState();
    _liveMapBloc = Modular.get<LiveMapBloc>();
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
    unawaited(_routeTrackingTask.dispose());
    unawaited(_chatRepository?.dispose());
    unawaited(_liveMapBloc.close());
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
        final pos =
            LocationService.lastPosition ??
            await LocationService.getCurrentPosition();
        if (pos != null) {
          if (mounted) {
            _liveMapBloc.add(
              DispatchTelemetryLocationEvent(
                lat: pos.latitude,
                lng: pos.longitude,
              ),
            );
          }
          if (mounted && _pickupLat != null && _pickupLng != null) {
            _liveMapBloc.add(
              UpdateLocationsAndDrawRouteEvent(
                driverLat: pos.latitude,
                driverLng: pos.longitude,
                passengerLat: _pickupLat!,
                passengerLng: _pickupLng!,
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

      final chatRepo = _chatRepository;
      if (chatRepo == null) return;
      final result = await chatRepo.fetchRoomMessages(rideId);
      result.fold((_) => null, (List<ChatMessage> messages) {
        final passengerChatMessagesList = messages
            .where((m) => m.senderId != driverIdentifier)
            .toList();
        final currentPassengerMessagesCount = passengerChatMessagesList.length;

        if (!_isInitialChatMessagesCountFetched) {
          // Existing passenger messages are unread until this chat is opened.
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
      if (rideState is RideFlowNavigatingToPickup) {
        _pickupLat = rideState.pickupLat;
        _pickupLng = rideState.pickupLng;
      } else {
        final places = await MapProvider.searchPlaces(widget.pickup);
        if (places.isNotEmpty) {
          _pickupLat = places.first.latitude;
          _pickupLng = places.first.longitude;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      final pos =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (pos != null) {
        _triggerDrawRoute(pos.latitude, pos.longitude);
      }
      _startRouteTracking();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Unable to load pickup route: $error\n$stackTrace');
    }
  }

  void _triggerDrawRoute(double dLat, double dLng) {
    final pickupLat = _pickupLat;
    final pickupLng = _pickupLng;
    if (pickupLat == null || pickupLng == null) return;
    _liveMapBloc.add(
      UpdateLocationsAndDrawRouteEvent(
        driverLat: dLat,
        driverLng: dLng,
        passengerLat: pickupLat,
        passengerLng: pickupLng,
      ),
    );
  }

  void _onMapCreated(AppMapController controller) {
    final pos = LocationService.lastPosition;
    final defaultLat = pos?.latitude ?? _pickupLat;
    final defaultLng = pos?.longitude ?? _pickupLng;
    if (defaultLat == null || defaultLng == null) return;

    _liveMapBloc.add(
      InitializeMapEvent(
        controller: controller,
        defaultLat: defaultLat,
        defaultLng: defaultLng,
        routeColor: context.colorScheme.primary,
      ),
    );

    if (!_isLoading) {
      _triggerDrawRoute(defaultLat, defaultLng);
    }
  }

  Future<void> _confirmArrival(BuildContext context) async {
    if (_isConfirmingArrival) return;
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowNavigatingToPickup
        ? state.passengerName
        : 'Passenger';
    final pickupState = state is RideFlowNavigatingToPickup ? state : null;
    final pickupLat = pickupState?.pickupLat ?? _pickupLat;
    final pickupLng = pickupState?.pickupLng ?? _pickupLng;
    if (pickupLat == null || pickupLng == null) return;

    setState(() => _isConfirmingArrival = true);
    final rideCubit = BlocProvider.of<RideFlowCubit>(context);
    try {
      await rideCubit.arriveAtPickup(
        passengerName,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destLat: pickupState?.destLat,
        destLng: pickupState?.destLng,
      );
      if (!mounted) return;
      if (rideCubit.state is! RideFlowWaitingPassenger) {
        CustomToast.show(
          this.context,
          'Unable to confirm arrival. Please try again.',
          isError: true,
        );
        return;
      }
      this.context.pushReplacementNamed(
        TripRoutes.waitingPassenger,
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
          'Unable to confirm arrival. Please try again.',
          isError: true,
        );
      }
      debugPrint('Unable to confirm driver arrival: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingArrival = false;
          _sliderVal = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveMapBloc>.value(
      value: _liveMapBloc,
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final position = LocationService.lastPosition;
          final pickupState = rideCubitState is RideFlowNavigatingToPickup
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
            backgroundColor: context.colorScheme.surface,
            body: Stack(
              children: [
                Positioned.fill(
                  child: SizedBox.expand(
                    child: MapProvider.buildMapView(
                      latitude: defaultLat,
                      longitude: defaultLng,
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
                      builder: (ctx, constraints) {
                        final isWide = constraints.maxWidth > 600.0;
                        final rideState = BlocProvider.of<RideFlowCubit>(
                          context,
                        ).state;
                        final passengerName =
                            rideState is RideFlowNavigatingToPickup
                            ? rideState.passengerName
                            : 'Passenger';

                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide ? 600.0 : double.infinity,
                          ),
                          child: PickupNavigationPanelWidget(
                            pickup: widget.pickup,
                            dropoff: widget.dropoff,
                            passengerName: passengerName,
                            distance: widget.distance,
                            fare: widget.fare,
                            sliderValue: _sliderVal,
                            isConfirmingArrival: _isConfirmingArrival,
                            unreadChatMessagesCount: _unreadChatMessagesCount,
                            onSliderChanged: (val) {
                              setState(() {
                                _sliderVal = val;
                              });
                            },
                            onSliderCompleted: () => _confirmArrival(context),
                            onCallPressed: () async {
                              try {
                                final rideCubit =
                                    BlocProvider.of<RideFlowCubit>(context);
                                final rideId = rideCubit.activeRideId ?? '';
                                if (rideId.isNotEmpty) {
                                  String? phone;
                                  (await widget.rideRepository
                                          .fetchCounterparty(rideId))
                                      .fold(
                                        (_) {},
                                        (passenger) => phone = passenger.phone,
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
                                  BlocProvider.of<RideFlowCubit>(
                                    context,
                                  ).activeRideId ??
                                  '';
                              final state = BlocProvider.of<RideFlowCubit>(
                                context,
                              ).state;
                              final pName = state is RideFlowNavigatingToPickup
                                  ? state.passengerName
                                  : 'Passenger';
                              final driverId =
                                  await widget.sessionService.readDriverId() ??
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: _buildTripBackButton(context, () => context.pop()),
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
          width: 46,
          height: 46,
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

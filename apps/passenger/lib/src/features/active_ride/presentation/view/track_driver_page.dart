import 'dart:async';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/maps.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_panel_widget.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:url_launcher/url_launcher.dart';

class const _MapUpdateRequest({
  required this.driverLat,
  required this.driverLng,
  required this.routeCoordinates,
  required this.status,
  required this.driverName,
}) {
  final double driverLat;
  final double driverLng;
  final Float64List? routeCoordinates;
  final RideStatus status;
  final String driverName;
}

class const TrackDriverPage({
  super.key,
  required this.ride,
  required this.trackRepository,
  required this.chatRepositoryFactory,
  required this.sessionService,
  required this.lifecycleCoordinator,
  this.realtimeClient,
}) extends StatefulWidget {
  final RideHistory ride;
  final TrackRepository trackRepository;
  final ChatRepositoryFactory chatRepositoryFactory;
  final PassengerSessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final RealtimeWebSocketClient? realtimeClient;

  @override
  State<TrackDriverPage> createState() => _TrackDriverPageState();
}

class _TrackDriverPageState extends State<TrackDriverPage> {
  AppMapController? _mapController;
  bool _initialized = false;
  bool _hasFittedInitialMap = false;
  bool _isUpdatingMap = false;
  _MapUpdateRequest? _pendingMapUpdate;
  bool _hasHandledTerminalState = false;
  DateTime? _lastCameraFitAt;
  mapbox.PointAnnotationManager? _passengerMarkerManager;
  mapbox.PointAnnotationManager? _driverMarkerManager;
  mapbox.PolylineAnnotationManager? _routeLineManager;
  StreamSubscription<Position>? _locationSubscription;
  LiveMapBloc? _liveMapBloc;

  int _unreadChatMessagesCount = 0;
  int _viewedDriverMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;
  late final AppLifecyclePeriodicTask _chatMessagesPollingTask;
  ChatRepository? _chatRepository;
  String _passengerIdentifier = '';
  bool _isCancellingTrip = false;
  bool _isPollingChat = false;

  @override
  void initState() {
    super.initState();
    _liveMapBloc = Modular.get<LiveMapBloc>();
    widget.realtimeClient?.setActiveTripResyncHandler(_resyncActiveTrip);
    _chatMessagesPollingTask = AppLifecyclePeriodicTask(
      lifecycleCoordinator: widget.lifecycleCoordinator,
      interval: const Duration(seconds: 4),
      onTick: _updateUnreadMessagesCount,
      runImmediately: true,
    );
    unawaited(_initializeChatRepository());
    _chatMessagesPollingTask.start();
  }

  Future<void> _initializeChatRepository() async {
    final passengerIdentifier =
        await widget.sessionService.readPassengerId() ?? '';
    if (!mounted || passengerIdentifier.isEmpty) return;
    _passengerIdentifier = passengerIdentifier;
    _chatRepository = widget.chatRepositoryFactory.create(
      currentUserId: passengerIdentifier,
    );
    unawaited(_updateUnreadMessagesCount());
  }

  @override
  void dispose() {
    widget.realtimeClient?.setActiveTripResyncHandler(null);
    unawaited(_locationSubscription?.cancel());
    unawaited(_chatMessagesPollingTask.dispose());
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

  Future<void> _resyncActiveTrip() async {
    if (!mounted) return;
    await BlocProvider.of<TrackDriverCubit>(context).resyncActiveTrip();
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
      _locationSubscription = LocationService.getPositionStream().listen((pos) {
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
    Float64List? routeCoordinates,
    RideStatus status,
    String driverName,
  ) async {
    final mapController = _mapController;
    final request = _MapUpdateRequest(
      driverLat: driverLat,
      driverLng: driverLng,
      routeCoordinates: routeCoordinates,
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
            pending.routeCoordinates,
            pending.status,
            pending.driverName,
          ),
        );
      }
    }
  }

  Future<mapbox.PointAnnotationManager> _upsertMarker(
    mapbox.PointAnnotationManager? annotationManager,
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

  Future<mapbox.PolylineAnnotationManager> _upsertRoute(
    mapbox.PolylineAnnotationManager? annotationManager,
    AppMapController mapController,
    Float64List routeCoordinates,
  ) async {
    if (annotationManager == null) {
      return MapProvider.addPolylineBuffer(
        mapController,
        routeCoordinates,
        color: context.colorScheme.onSurface,
        width: 4.0,
      );
    }
    await MapProvider.replacePolylineBuffer(
      annotationManager,
      routeCoordinates,
      color: context.colorScheme.onSurface,
      width: 4.0,
    );
    return annotationManager;
  }

  Future<void> _handleCancelTrip() async {
    if (_isCancellingTrip) return;
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Cancel Trip?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this trip? A cancellation fee may apply.',
          style: TextStyle(
            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Ride',
              style: TextStyle(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: Text(
              'Cancel Trip',
              style: TextStyle(
                color: context.colorScheme.error,
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
      final canceled = await BlocProvider.of<TrackDriverCubit>(context)
          .cancelTripRequest();
      if (mounted && !canceled) {
        CustomToast.show(
          context,
          'The trip could not be canceled. Please try again.',
          isError: true,
        );
      }
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
        switch (state) {
          case DriverEnRoute(
            :final driverLat,
            :final driverLng,
            :final routePoints,
            :final status,
            :final driverName,
          ):
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
            Modular.get<BookingBloc>().add(const ResetBookingEvent());
            context.pushReplacementNamed(
              RideHistoryRoutes.passengerPayment,
              extra: widget.ride.copyWith(
                driverId: driverId,
                driverName: driverName,
              ),
            );
          case RideFailed():
            if (_hasHandledTerminalState) return;
            _hasHandledTerminalState = true;
            Modular.get<BookingBloc>().add(const ResetBookingEvent());
            if (mounted) {
              context.goNamed(HomeRoutes.home);
            }
          case Idle() || SearchingDriver():
            return;
        }
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
                    final isInTransit = state.isInTransit;
                    final hasArrived = state.hasArrived;
                    final statusTitle = isInTransit
                        ? 'Heading To Your Destination'
                        : hasArrived
                        ? 'Driver Has Arrived'
                        : state.isTracking
                        ? 'Driver Is Picking You Up'
                        : 'Driver Assigned';
                    final statusSubtitle = isInTransit
                        ? 'Heading To ${widget.ride.destination}'
                        : hasArrived
                        ? 'Meet Your Driver At Pickup'
                        : state.isTracking
                        ? 'Your Driver Is On The Way To Pickup'
                        : 'Your Driver Is Preparing For Pickup';
                    final etaText = switch (state) {
                      DriverEnRoute(:final status) =>
                        status == RideStatus.arrived
                            ? 'Driver Arrived'
                            : 'To Pickup',
                      TripInProgress() => 'To Drop Off',
                      Idle() ||
                      SearchingDriver() ||
                      TripCompleted() ||
                      RideFailed() => 'To Pickup',
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
                                  String phone = '';
                                  (await widget.trackRepository
                                          .fetchCounterpartyResult(rideId))
                                      .fold(
                                        (_) {},
                                        (driver) => phone = driver.phone,
                                      );

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
                                  await widget.sessionService
                                      .readPassengerId() ??
                                  '';
                              final dName = state.activeDriverName.isNotEmpty
                                  ? state.activeDriverName
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

import 'dart:async';
import 'dart:developer' as developer;

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/navigation_observer.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger/src/features/home/presentation/widgets/home_dialogs.dart';
import 'package:passenger/src/features/home/presentation/widgets/home_sections.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_state.dart';
import 'package:passenger/src/features/saved_places/presentation/widgets/saved_place_auth.dart';
import 'package:passenger/src/features/saved_places/saved_places_routes.dart';

bool shouldStartHomeNavigation({
  required bool isMounted,
  required bool isNavigationInFlight,
}) => isMounted && !isNavigationInFlight;

class const HomePage({
  super.key,
  required this.bookingBloc,
  required this.lifecycleCoordinator,
  this.sessionService,
  this.trackRepository,
}) extends StatefulWidget {
  final BookingBloc bookingBloc;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final SessionStore? sessionService;
  final TrackRepository? trackRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final BookingBloc _bookingBloc;
  late final HomeCubit _homeCubit;
  late final StreamSubscription<void> _routePopSubscription;
  late final StreamSubscription<AppLifecycleStatus> _lifecycleSubscription;
  bool _isSavedPlaceFlowOpen = false;
  bool _isNavigationInFlight = false;

  @override
  void initState() {
    super.initState();
    _bookingBloc = widget.bookingBloc;
    _homeCubit = BlocProvider.of<HomeCubit>(context, listen: false);
    _routePopSubscription = appNavigationObserver.routePopEvents.listen((_) {
      if (!mounted) return;
      _isNavigationInFlight = false;
      _refreshLocationSnapshot();
    });
    _lifecycleSubscription = widget.lifecycleCoordinator.changes.listen((
      status,
    ) {
      if (status == AppLifecycleStatus.foreground) {
        _refreshLocationSnapshot();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadSavedPlaces());
      _loadRecentRideHistory();
      unawaited(_restoreActiveRideOnLaunch());
      if (BlocProvider.of<SessionBloc>(context).state.isAuthenticated) {
        _bookingBloc.add(const RestoreActiveBookingEvent());
      }
      if (!mounted) return;
      if (BlocProvider.of<LocationAccessCubit>(context).state
          is LocationAccessReady) {
        unawaited(_homeCubit.startLocationTracking());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_routePopSubscription.cancel());
    unawaited(_lifecycleSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<SessionBloc, bool>(
      (bloc) => bloc.state.isAuthenticated,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<LocationAccessCubit, LocationAccessViewState>(
          listener: _handleLocationAccess,
        ),
        BlocListener<SavedPlacesCubit, SavedPlacesState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            if (ModalRoute.of(context)?.isCurrent != true) return;
            final errorMessage = state.errorMessage;
            if (errorMessage != null) {
              AppSnackBar.show(
                context,
                errorMessage,
                tone: AppSnackBarTone.error,
              );
            }
          },
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (_, current) => current is GuestSession,
          listener: (context, _) {
            BlocProvider.of<SavedPlacesCubit>(context).clear();
            _homeCubit.clearAccountContext();
            _refreshLocationSnapshot();
          },
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (_, current) => current is AuthenticatedSession,
          listener: (_, _) {
            unawaited(_loadSavedPlaces());
            _loadRecentRideHistory();
            _refreshLocationSnapshot();
            _bookingBloc.add(const RestoreActiveBookingEvent());
          },
        ),
        BlocListener<RideHistoryBloc, RideHistoryState>(
          listener: _syncUpcomingRideTracking,
        ),
      ],
      child: Scaffold(
        backgroundColor: context.canvasColor,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                top: true,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.pageMaxWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.sizeOf(context).width < 360
                            ? AppLayout.pagePadding
                            : AppLayout.pagePaddingWide,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppPageHeader(
                            title: 'EasyRide',
                            subtitle: 'Where to today?',
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          HomeSearchBar(
                            onTap: () => unawaited(_openDestinationFlow()),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          HomeSavedPlacesSection(
                            isAuthenticated: isAuthenticated,
                            onPlaceTap: (place) =>
                                unawaited(_handleSavedPlaceTap(place)),
                            onPlaceLongPress: (index, place) =>
                                unawaited(_showChipOptions(index, place)),
                            onAddPlace: () =>
                                unawaited(_openNewSavedPlaceFlow()),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Semantics(
                            header: true,
                            child: Text(
                              'RECENT ACTIVITY',
                              style: context.textStyles.labelSmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Expanded(
                            child: HomeRecentActivitySection(
                              isAuthenticated: isAuthenticated,
                              onRideTap: (ride) => unawaited(
                                context.pushNamed(
                                  RideHistoryRoutes.rideDetails,
                                  extra: ride,
                                ),
                              ),
                              onRetry: _loadRecentRideHistory,
                            ),
                          ),
                        ],
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
  }

  void _syncUpcomingRideTracking(BuildContext context, RideHistoryState state) {
    if (state is! RideHistoryLoaded || state.upcoming.isEmpty) return;
    final upcoming = state.upcoming.first;
    final trackCubit = _getTrackDriverCubit();
    if (trackCubit != null &&
        !trackCubit.state.isTracking &&
        !trackCubit.state.isTerminal) {
      unawaited(
        trackCubit.startTracking(
          startLat: upcoming.pickupLat,
          startLng: upcoming.pickupLng,
          endLat: upcoming.pickupLat,
          endLng: upcoming.pickupLng,
          rideId: upcoming.id,
          driverId: upcoming.driverId,
          driverName: upcoming.displayDriverName,
          vehiclePlate: upcoming.vehiclePlate,
          vehicleType: upcoming.vehicleType,
          destinationLat: upcoming.destLat,
          destinationLng: upcoming.destLng,
        ),
      );
    }
  }

  Future<void> _restoreActiveRideOnLaunch() async {
    try {
      final session = widget.sessionService;
      final trackRepository = widget.trackRepository;
      if (session == null || trackRepository == null) return;

      final activeRideId = await session.readActiveRideId();
      if (activeRideId == null || activeRideId.trim().isEmpty) return;

      final result = await trackRepository.fetchRideResult(activeRideId.trim());
      switch (result) {
        case Err(:final failure):
          final failureMessage = failure.message.toLowerCase();
          if ((failure is ServerFailure && failure.statusCode == 404) ||
              failureMessage.contains('not found') ||
              failureMessage.contains('incomplete')) {
            await session.saveActiveRideId('');
          }
        case Ok(value: final snapshot):
          if (!mounted) return;
          if (snapshot.isTerminal) {
            await session.saveActiveRideId('');
            return;
          }
          unawaited(
            context.pushNamed(ActiveRideRoutes.trackDriver, extra: snapshot),
          );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Unable to restore active ride on passenger home launch.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _refreshLocationSnapshot() {
    if (!mounted ||
        BlocProvider.of<LocationAccessCubit>(context).state
            is! LocationAccessReady) {
      return;
    }
    unawaited(_homeCubit.startLocationTracking());
  }

  void _loadRecentRideHistory() {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      if (passengerId.trim().isEmpty) return;
      BlocProvider.of<RideHistoryBloc>(context)
          .add(LoadRideHistoryEvent(passengerId: passengerId));
    }
  }

  void _handleLocationAccess(
    BuildContext context,
    LocationAccessViewState state,
  ) {
    final homeCubit = BlocProvider.of<HomeCubit>(context);
    switch (state) {
      case LocationAccessReady():
        unawaited(homeCubit.startLocationTracking());
      case LocationAccessUnavailable():
        unawaited(homeCubit.stopLocationTracking(clearAddress: true));
      case LocationAccessChecking():
        break;
    }
  }

  Future<void> _openNewSavedPlaceFlow() async {
    if (_isSavedPlaceFlowOpen) return;
    _isSavedPlaceFlowOpen = true;
    try {
      if (!await ensureSavedPlaceAuthentication(context) || !mounted) return;
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed<Place>(
        BookingRoutes.mapPin,
        queryParameters: {'savedPlace': '1'},
      );
      if (selectedPlace == null || !mounted) return;
      final newPlace = await context.pushNamed<SavedPlace>(
        SavedPlacesRoutes.addCategory,
        extra: {'place': selectedPlace},
      );
      if (newPlace != null && mounted) {
        await cubit.addPlace(newPlace);
        if (mounted &&
            cubit.state.errorSource != SavedPlacesErrorSource.persistence) {
          AppSnackBar.show(context, '${newPlace.label} saved.');
        }
      }
    } finally {
      _isSavedPlaceFlowOpen = false;
    }
  }

  TrackDriverCubit? _getTrackDriverCubit() {
    try {
      return BlocProvider.of<TrackDriverCubit>(context);
    } catch (_) {
      return null;
    }
  }

  RideHistory? _activeRideFromHistory(RideHistoryState state) {
    if (state is RideHistoryLoaded && state.upcoming.isNotEmpty) {
      return state.upcoming.first;
    }
    return null;
  }

  bool _hasActiveRide() {
    final trackDriverCubit = _getTrackDriverCubit();
    if (trackDriverCubit?.state.isTracking == true) return true;
    if (trackDriverCubit?.state.isTerminal == true) return false;
    return _activeRideFromHistory(
          BlocProvider.of<RideHistoryBloc>(context).state,
        ) !=
        null;
  }

  bool _hasBlockingBooking() =>
      _bookingBloc.state.isBlockingBooking ||
      _bookingBloc.hasActiveDriverSearch;

  void _resumeActiveRide() => unawaited(_resumeActiveRideById());

  Future<void> _resumeActiveRideById() async {
    final trackDriverCubit = _getTrackDriverCubit();
    if (trackDriverCubit?.state.isTerminal == true) return;

    // Ride-history fallback remains available if session storage is absent.
    final session = widget.sessionService;

    String? activeRideId;
    try {
      activeRideId = await session?.readActiveRideId();
    } catch (error, stackTrace) {
      developer.log(
        'Unable to read active ride id from session store.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!mounted) return;
    if (activeRideId != null && activeRideId.trim().isNotEmpty) {
      unawaited(
        context.pushNamed(
          ActiveRideRoutes.trackDriver,
          extra: activeRideId.trim(),
        ),
      );
      return;
    }

    final historyState = BlocProvider.of<RideHistoryBloc>(context).state;
    if (historyState is RideHistoryLoaded && historyState.upcoming.isNotEmpty) {
      unawaited(
        context.pushNamed(
          ActiveRideRoutes.trackDriver,
          extra: historyState.upcoming.first.id,
        ),
      );
    }
  }

  Future<bool> _canStartOrContinueBooking() async {
    if (!shouldStartHomeNavigation(
      isMounted: mounted,
      isNavigationInFlight: _isNavigationInFlight,
    )) {
      return false;
    }
    if (_hasActiveRide()) {
      _isNavigationInFlight = true;
      try {
        final trackDriverCubit = _getTrackDriverCubit();
        final historyRide = _activeRideFromHistory(
          BlocProvider.of<RideHistoryBloc>(context).state,
        );
        final driverName =
            trackDriverCubit != null &&
                trackDriverCubit.state.activeDriverName.isNotEmpty
            ? trackDriverCubit.state.activeDriverName
            : historyRide?.displayDriverName ?? 'your driver';
        await showHomeActiveRideBlockedDialog(
          context,
          driverName: driverName,
          onResumeTrip: _resumeActiveRide,
        );
      } finally {
        _isNavigationInFlight = false;
      }
      return false;
    }
    if (_hasBlockingBooking()) {
      _isNavigationInFlight = true;
      try {
        await showHomeActiveBookingBlockedDialog(
          context,
          bookingState: _bookingBloc.state,
          activeSearch: _bookingBloc.activeDriverSearch,
          onRetryRecovery: () =>
              _bookingBloc.add(const RestoreActiveBookingEvent()),
          onResumeMatchedRide: (rideId) {
            final trimmed = rideId?.trim() ?? '';
            if (trimmed.isNotEmpty) {
              unawaited(
                context.pushNamed(ActiveRideRoutes.trackDriver, extra: trimmed),
              );
            } else {
              _resumeActiveRide();
            }
          },
          onOpenActiveSearch: (search) =>
              unawaited(_openActiveDriverSearch(search)),
        );
      } finally {
        _isNavigationInFlight = false;
      }
      return false;
    }
    return mounted;
  }

  Future<void> _openActiveDriverSearch(ActiveDriverSearch activeSearch) async {
    if (!mounted) return;
    final trip = activeSearch.trip;
    await context.pushNamed(
      BookingRoutes.findingDriver,
      extra: {
        'fare': trip.fare,
        'destination': trip.destination,
        'distance': trip.distance,
        'duration': trip.duration,
        if (activeSearch.distanceKm != null)
          'distanceKm': activeSearch.distanceKm,
        if (activeSearch.durationMinutes != null)
          'durationMinutes': activeSearch.durationMinutes,
        'pickupAddress': trip.pickupAddress,
        'pickupLat': activeSearch.pickupLat,
        'pickupLng': activeSearch.pickupLng,
        'passengerNote': trip.passengerNote,
      },
    );
  }

  Future<void> _openDestinationFlow() async {
    if (!await _canStartOrContinueBooking() || !mounted) return;
    _isNavigationInFlight = true;
    try {
      final address = BlocProvider.of<HomeCubit>(context).state.currentAddress;
      await context.pushNamed(
        BookingRoutes.searchDestination,
        queryParameters: {'pickupAddress': address},
      );
    } finally {
      _isNavigationInFlight = false;
    }
  }

  Future<void> _handleSavedPlaceTap(SavedPlace place) async {
    if (!await ensureSavedPlaceAuthentication(context) || !mounted) return;
    if (!await _canStartOrContinueBooking() || !mounted) return;
    final latitude = place.latitude;
    final longitude = place.longitude;
    if (latitude != null && longitude != null) {
      _isNavigationInFlight = true;
      try {
        final syntheticPlace = Place(
          id: 'saved_${place.label.toLowerCase().replaceAll(' ', '_')}',
          name: place.label,
          fullAddress: place.savedAddress ?? place.label,
          latitude: latitude,
          longitude: longitude,
        );
        final address = BlocProvider.of<HomeCubit>(context)
            .state
            .currentAddress;
        final position = LocationService.lastPosition;
        await context.pushNamed(
          BookingRoutes.rideSelection,
          extra: syntheticPlace,
          queryParameters: {
            'pickupAddress': address,
            if (position != null) ...{
              'pickupLat': position.latitude.toString(),
              'pickupLng': position.longitude.toString(),
            },
          },
        );
      } finally {
        _isNavigationInFlight = false;
      }
    } else {
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed(
        BookingRoutes.mapPin,
        queryParameters: {'savedPlace': '1'},
      );
      if (selectedPlace == null || selectedPlace is! Place) return;
      if (!mounted) return;
      final updatedPlace = await context.pushNamed<SavedPlace>(
        SavedPlacesRoutes.addCategory,
        extra: {
          'place': selectedPlace,
          'initialLabel': place.label,
          'initialIconName': place.iconName,
          'isEditing': true,
        },
      );
      if (updatedPlace != null && mounted) {
        final existingIndex = cubit.state.places.indexOf(place);
        if (existingIndex >= 0) {
          await cubit.replacePlace(existingIndex, updatedPlace);
        } else {
          await cubit.addPlace(updatedPlace);
        }
        final hadPersistenceError =
            cubit.state.errorSource == SavedPlacesErrorSource.persistence;
        if (!hadPersistenceError) {
          await cubit.invalidateAndReload();
          if (mounted) {
            AppSnackBar.show(context, '${updatedPlace.label} updated.');
          }
        }
      }
    }
  }

  Future<void> _loadSavedPlaces() async {
    if (!mounted) return;
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    if (!BlocProvider.of<SessionBloc>(context).state.isAuthenticated) {
      cubit.clear();
      return;
    }
    await cubit.loadPlaces();
  }

  Future<void> _showChipOptions(int index, SavedPlace place) async {
    if (!await ensureSavedPlaceAuthentication(context) || !mounted) return;
    await showSavedPlaceChipOptionsSheet(
      context,
      label: place.label,
      onRemove: () async {
        if (!mounted) return;
        final cubit = BlocProvider.of<SavedPlacesCubit>(context);
        await cubit.removePlace(index);
        if (!mounted) return;
        if (cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
          return;
        }
        AppSnackBar.show(
          context,
          '${place.label} removed.',
          tone: AppSnackBarTone.info,
          actionLabel: 'Undo',
          onAction: () => unawaited(cubit.restorePlace(index, place)),
        );
      },
    );
  }
}

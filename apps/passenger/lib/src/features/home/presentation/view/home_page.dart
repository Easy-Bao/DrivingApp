import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/navigation/passenger_navigation_observer.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger/src/features/home/presentation/widgets/active_ride_banner_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/home_destination_search_hint_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/pending_booking_banner_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_empty_state_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_preview_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/saved_place_quick_actions_widget.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_state.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const HomePage({
  super.key,
  required this.bookingBloc,
  required this.lifecycleCoordinator,
  this.sessionService,
  this.trackRepository,
}) extends StatefulWidget {
  final BookingBloc bookingBloc;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final PassengerSessionStore? sessionService;
  final TrackRepository? trackRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _recentRideHistoryPreviewLimit = 5;

  late final BookingBloc _bookingBloc;
  late final HomeCubit _homeCubit;
  late final StreamSubscription<void> _routePopSubscription;
  late final StreamSubscription<AppLifecycleStatus> _lifecycleSubscription;
  bool _isSavedPlaceFlowOpen = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LocationAccessCubit, LocationAccessViewState>(
          listener: _handleLocationAccess,
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (_, current) => current is AuthenticatedSession,
          listener: (_, _) {
            _loadRecentRideHistory();
            _refreshLocationSnapshot();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.canvasColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: EasyRideLayout.pageMaxWidth,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EasyRideLayout.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildActiveRideBanner(),
                        _buildSearchBar(),
                        _buildPendingBookingBanner(),
                        const SizedBox(height: 16),
                        _buildChipRow(),
                        const SizedBox(height: 24),
                        _buildRecentRideHistoryHeader(),
                        Expanded(child: _buildRecentRideHistoryList()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _bookingBloc = widget.bookingBloc;
    _homeCubit = BlocProvider.of<HomeCubit>(context, listen: false);
    _routePopSubscription = passengerNavigationObserver.routePopEvents.listen(
      (_) => _refreshLocationSnapshot(),
    );
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
      if (!mounted) return;
      if (BlocProvider.of<LocationAccessCubit>(context).state
          is LocationAccessReady) {
        unawaited(_homeCubit.startLocationTracking());
      }
    });
  }

  Future<void> _restoreActiveRideOnLaunch() async {
    try {
      PassengerSessionStore? session = widget.sessionService;
      if (session == null) {
        try {
          session = Modular.get<PassengerSessionStore>();
        } catch (_) {
          return;
        }
      }
      final activeRideId = await session.readActiveRideId();
      if (activeRideId == null || activeRideId.trim().isEmpty) return;

      TrackRepository? trackRepo = widget.trackRepository;
      if (trackRepo == null) {
        try {
          trackRepo = Modular.get<TrackRepository>();
        } catch (_) {
          return;
        }
      }
      final result = await trackRepo.fetchRideResult(activeRideId.trim());
      await result.fold(
        (failure) async {
          final msg = failure.message.toLowerCase();
          if ((failure is ServerFailure && failure.statusCode == 404) ||
              msg.contains('not found') ||
              msg.contains('incomplete')) {
            await session?.saveActiveRideId('');
          }
        },
        (snapshot) async {
          if (!mounted) return;
          if (snapshot.isTerminal) {
            await session?.saveActiveRideId('');
            return;
          }
          final ride = snapshot.toRideHistory();
          final trackDriverCubit = _getTrackDriverCubit();
          if (trackDriverCubit != null) {
            trackDriverCubit.currentRide = ride;
          }
          if (mounted) {
            unawaited(
              context.pushNamed(ActiveRideRoutes.trackDriver, extra: ride),
            );
          }
        },
      );
    } catch (_) {
      // Best-effort active trip restoration on app launch.
    }
  }

  @override
  void dispose() {
    unawaited(_routePopSubscription.cancel());
    unawaited(_lifecycleSubscription.cancel());
    super.dispose();
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

  Widget _buildChipRow() {
    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      builder: (context, state) {
        if (state.isLoading && state.places.isNotEmpty) {
          final placeholderCount = state.places.length + 1;
          return Skeletonizer.zone(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var index = 0; index < placeholderCount; index++)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Bone.button(
                        width: 90,
                        height: 38,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return SavedPlaceQuickActionsWidget(
          places: state.places,
          onPlaceTap: (place) => unawaited(_handleSavedPlaceTap(place)),
          onPlaceLongPress: (place) {
            final index = state.places.indexOf(place);
            if (index >= 0) {
              unawaited(_showChipOptions(index, place.label));
            }
          },
          onAddPlace: _openNewSavedPlaceFlow,
        );
      },
    );
  }

  Widget _buildPendingBookingBanner() {
    final isAuthenticated = context.select<SessionBloc, bool>(
      (bloc) => bloc.state.isAuthenticated,
    );

    return BlocBuilder<BookingDraftCubit, BookingDraftState>(
      buildWhen: (previous, current) => previous.draft != current.draft,
      builder: (context, state) {
        final draft = state.draft;
        if (draft == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PendingBookingBannerWidget(
            isAuthenticated: isAuthenticated,
            destinationName: draft.destination.name,
            onContinue: () {
              final pickupAddress = draft.pickupAddress;
              final position = LocationService.lastPosition;
              BlocProvider.of<BookingDraftCubit>(context).clear();
              unawaited(
                context.pushNamed(
                  BookingRoutes.rideSelection,
                  extra: {
                    'destination': draft.destination,
                    'tipAmount': draft.tipAmount,
                    'notes': draft.notes,
                  },
                  queryParameters: {
                    if (pickupAddress != null && pickupAddress.isNotEmpty)
                      'pickupAddress': pickupAddress,
                    if (position != null) ...{
                      'pickupLat': position.latitude.toString(),
                      'pickupLng': position.longitude.toString(),
                    },
                  },
                ),
              );
            },
            onDismiss: () =>
                BlocProvider.of<BookingDraftCubit>(context).clear(),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const EasyRidePageHeader(
      title: 'EasyRide',
      subtitle: 'Ready to ride today?',
    );
  }

  Widget _buildRecentRideHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recent Activity', style: context.textStyles.titleLarge),
        if (context.select<SessionBloc, bool>(
          (bloc) => bloc.state.isAuthenticated,
        ))
          TextButton(
            onPressed: () =>
                context.pushNamed(RideHistoryRoutes.recentActivity),
            child: const Text('View all'),
          ),
      ],
    );
  }

  Widget _buildRecentRideHistoryList() {
    final isGuest = context.select<SessionBloc, bool>((bloc) {
      final sessionState = bloc.state;
      return sessionState is GuestSession || sessionState is SessionFailure;
    });

    return BlocBuilder<RideHistoryBloc, RideHistoryState>(
      builder: (context, state) {
        if (state is RideHistoryLoading && state.hasExistingRides) {
          final itemCount = state.existingRideCount
              .clamp(1, _recentRideHistoryPreviewLimit)
              .toInt();
          return Skeletonizer.zone(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: itemCount,
              itemBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Row(
                  children: [
                    Bone.square(
                      size: 36,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    SizedBox(width: 14),
                    Expanded(child: Bone.multiText(lines: 2, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is RideHistoryError) {
          return _buildRecentRideHistoryError();
        }
        if (state is! RideHistoryLoaded) {
          return RecentRideHistoryEmptyStateWidget(isGuest: isGuest);
        }
        final recentRides = state.past
            .take(_recentRideHistoryPreviewLimit)
            .toList(growable: false);
        if (recentRides.isEmpty) {
          return RecentRideHistoryEmptyStateWidget(isGuest: isGuest);
        }
        return RecentRideHistoryPreviewWidget(
          rides: recentRides,
          onRideTap: (ride) => unawaited(
            context.pushNamed(RideHistoryRoutes.rideDetails, extra: ride),
          ),
        );
      },
    );
  }

  Widget _buildRecentRideHistoryError() {
    return Center(
      child: TextButton.icon(
        onPressed: _loadRecentRideHistory,
        icon: const Icon(LucideIcons.refresh_cw, size: 16),
        label: const Text('Retry activity'),
        style: TextButton.styleFrom(
          foregroundColor: context.colorScheme.onSurface,
        ),
      ),
    );
  }

  Future<void> _openNewSavedPlaceFlow() async {
    if (_isSavedPlaceFlowOpen) return;
    _isSavedPlaceFlowOpen = true;
    try {
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed<Place>(
        BookingRoutes.mapPin,
      );
      if (selectedPlace == null || !mounted) return;
      final newPlace = await context.pushNamed<SavedPlace>(
        HomeRoutes.addCategory,
        extra: {'place': selectedPlace},
      );
      if (newPlace != null && mounted) {
        await cubit.addPlace(newPlace);
        final error = cubit.state.errorMessage;
        if (mounted && error != null) {
          CustomToast.show(context, error, isError: true);
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

  Widget _buildActiveRideBanner() {
    final cubit = _getTrackDriverCubit();
    return BlocBuilder<RideHistoryBloc, RideHistoryState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, historyState) {
        final historyRide = _activeRideFromHistory(historyState);
        if (cubit == null) {
          return _buildRestoredRideBanner(historyRide);
        }
        return BlocBuilder<TrackDriverCubit, TrackDriverState>(
          bloc: cubit,
          builder: (context, state) {
            if (!state.isTracking) {
              return _buildRestoredRideBanner(historyRide);
            }

            final driverName = state.activeDriverName.isNotEmpty
                ? state.activeDriverName
                : historyRide?.displayDriverName ?? 'Driver';
            final vehicleInfo = [
              state.activeVehicleType,
              state.activeVehiclePlate,
            ].where((value) => value.trim().isNotEmpty).join(' • ');
            final statusText = state.isInTransit
                ? 'Heading to Destination'
                : state.hasArrived
                ? 'Driver Has Arrived'
                : 'Driver is Picking You Up';

            return ActiveRideBannerWidget(
              statusText: statusText,
              driverName: driverName,
              vehicleInfo: vehicleInfo,
              onResume: _resumeActiveRide,
            );
          },
        );
      },
    );
  }

  Widget _buildRestoredRideBanner(RideHistory? ride) {
    if (ride == null) return const SizedBox.shrink();
    return ActiveRideBannerWidget(
      statusText: _activeRideStatusText(ride),
      driverName: ride.displayDriverName,
      vehicleInfo: ride.displayVehicleSummary,
      onResume: _resumeActiveRide,
    );
  }

  RideHistory? _activeRideFromHistory(RideHistoryState state) {
    if (state is RideHistoryLoaded && state.upcoming.isNotEmpty) {
      return state.upcoming.first;
    }
    return null;
  }

  String _activeRideStatusText(RideHistory ride) {
    return switch (RideStatus.fromString(ride.status)) {
      RideStatus.inTransit => 'Heading to Destination',
      RideStatus.arrived => 'Driver Has Arrived',
      RideStatus.accepted => 'Driver is Picking You Up',
      RideStatus.requested => 'Finding Your Driver',
      RideStatus.completed ||
      RideStatus.cancelled ||
      RideStatus.unknown => 'Active Ride',
    };
  }

  bool _hasActiveRide() {
    final trackDriverCubit = _getTrackDriverCubit();
    if (trackDriverCubit?.state.isTracking == true) return true;
    return _activeRideFromHistory(
          BlocProvider.of<RideHistoryBloc>(context).state,
        ) !=
        null;
  }

  void _resumeActiveRide() {
    final trackDriverCubit = _getTrackDriverCubit();
    final ride = trackDriverCubit?.currentRide;
    if (ride != null) {
      unawaited(context.pushNamed(ActiveRideRoutes.trackDriver, extra: ride));
      return;
    }

    final historyState = BlocProvider.of<RideHistoryBloc>(context).state;
    if (historyState is RideHistoryLoaded && historyState.upcoming.isNotEmpty) {
      unawaited(
        context.pushNamed(
          ActiveRideRoutes.trackDriver,
          extra: historyState.upcoming.first,
        ),
      );
      return;
    }
  }

  Future<void> _showActiveRideBlockedDialog() async {
    final trackDriverCubit = _getTrackDriverCubit();
    final historyRide = _activeRideFromHistory(
      BlocProvider.of<RideHistoryBloc>(context).state,
    );
    final driverName =
        trackDriverCubit != null &&
            trackDriverCubit.state.activeDriverName.isNotEmpty
        ? trackDriverCubit.state.activeDriverName
        : historyRide?.displayDriverName ?? 'your driver';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        ),
        title: Text(
          'Active Ride in Progress',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: ctx.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'You already have an active trip with $driverName. Please complete or cancel your ongoing ride before booking another.',
          style: TextStyle(
            color: ctx.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resumeActiveRide();
            },
            child: const Text('Resume Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Semantics(
      button: true,
      label: 'Search for a destination',
      hint: 'Opens destination search',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_hasActiveRide()) {
            unawaited(_showActiveRideBlockedDialog());
            return;
          }
          final activeSearch = _bookingBloc.activeDriverSearch;
          if (activeSearch != null) {
            final trip = activeSearch.trip;
            unawaited(
              context.pushNamed(
                BookingRoutes.findingDriver,
                extra: {
                  'rideType': trip.rideType,
                  'fare': trip.fare,
                  'destination': trip.destination,
                  'distance': trip.distance,
                  'duration': trip.duration,
                  'pickupAddress': trip.pickupAddress,
                  'pickupLat': activeSearch.pickupLat,
                  'pickupLng': activeSearch.pickupLng,
                  'passengerNote': trip.passengerNote,
                },
              ),
            );
            return;
          }
          final address = BlocProvider.of<HomeCubit>(context)
              .state
              .currentAddress;
          unawaited(
            context.pushNamed(
              BookingRoutes.searchDestination,
              queryParameters: {'pickupAddress': address},
            ),
          );
        },
        child: Hero(
          tag: 'search_bar_field',
          child: Material(
            color: context.colorScheme.surface.withValues(alpha: 0),
            child: Container(
              padding: const EdgeInsets.all(EasyRideSpacing.lg),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    color: context.colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: HomeDestinationSearchHintWidget()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSavedPlaceTap(SavedPlace place) async {
    if (!mounted) return;
    if (place.hasLocation) {
      final syntheticPlace = Place(
        id: 'saved_${place.label.toLowerCase().replaceAll(' ', '_')}',
        name: place.label,
        fullAddress: place.savedAddress ?? place.label,
        latitude: place.latitude!,
        longitude: place.longitude!,
      );
      final address = BlocProvider.of<HomeCubit>(context).state.currentAddress;
      final position = LocationService.lastPosition;
      unawaited(
        context.pushNamed(
          BookingRoutes.rideSelection,
          extra: syntheticPlace,
          queryParameters: {
            'pickupAddress': address,
            if (position != null) ...{
              'pickupLat': position.latitude.toString(),
              'pickupLng': position.longitude.toString(),
            },
          },
        ),
      );
    } else {
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed(BookingRoutes.mapPin);
      if (selectedPlace == null || selectedPlace is! Place) return;
      if (!mounted) return;
      final updatedPlace = await context.pushNamed<SavedPlace>(
        HomeRoutes.addCategory,
        extra: {'place': selectedPlace, 'initialLabel': place.label},
      );
      if (updatedPlace != null && mounted) {
        final existingIndex = cubit.state.places.indexOf(place);
        if (existingIndex >= 0) {
          await cubit.replacePlace(existingIndex, updatedPlace);
        } else {
          await cubit.addPlace(updatedPlace);
        }
        await cubit.invalidateAndReload();
        final error = cubit.state.errorMessage;
        if (mounted && error != null) {
          CustomToast.show(context, error, isError: true);
        }
      }
    }
  }

  Future<void> _loadSavedPlaces() async {
    if (!mounted) return;
    await BlocProvider.of<SavedPlacesCubit>(context).loadPlaces();
  }

  Future _showChipOptions(int index, String label) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: context.colorScheme.outlineVariant),
            ListTile(
              leading: Icon(
                LucideIcons.trash_2,
                color: context.colorScheme.error,
                size: 20,
              ),
              title: Text(
                'Remove shortcut',
                style: TextStyle(
                  color: context.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await BlocProvider.of<SavedPlacesCubit>(context)
                    .removePlace(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

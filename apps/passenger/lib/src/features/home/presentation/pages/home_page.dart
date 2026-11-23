import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/navigation_observer.dart';
import 'package:passenger/src/core/location/location_access_cubit.dart';
import 'package:passenger/src/core/location/location_access_state.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_draft.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_state.dart';
import 'package:passenger/src/features/home/presentation/widgets/destination_search_hint.dart';
import 'package:passenger/src/features/home/presentation/widgets/pending_booking_banner.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_empty_state.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_preview.dart';
import 'package:passenger/src/features/home/presentation/widgets/saved_place_quick_actions.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_state.dart';
import 'package:passenger/src/features/saved_places/presentation/widgets/saved_place_auth.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  static const int _recentRideHistoryPreviewLimit = 5;

  late final BookingBloc _bookingBloc;
  late final HomeCubit _homeCubit;
  late final StreamSubscription<void> _routePopSubscription;
  late final StreamSubscription<AppLifecycleStatus> _lifecycleSubscription;
  bool _isSavedPlaceFlowOpen = false;
  bool _isNavigationInFlight = false;

  @override
  Widget build(BuildContext context) {
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
            AppSnackBar.show(context, state.errorMessage!, isError: true);
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
            _loadRecentRideHistory();
            _refreshLocationSnapshot();
            _bookingBloc.add(const RestoreActiveBookingEvent());
          },
        ),
        BlocListener<RideHistoryBloc, RideHistoryState>(
          listener: (context, state) {
            if (state is RideHistoryLoaded && state.upcoming.isNotEmpty) {
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
          },
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
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.sizeOf(context).width < 360
                                ? AppLayout.pagePadding
                                : AppLayout.pagePaddingWide,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: AppSpacing.xl),
                              _buildSearchBar(),
                              _buildPendingBookingBanner(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildChipRow(),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildRecentRideHistoryHeader(),
                              const SizedBox(height: AppSpacing.xs),
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
          ],
        ),
      ),
    );
  }

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

  Future<void> _restoreActiveRideOnLaunch() async {
    try {
      SessionStore? session = widget.sessionService;
      if (session == null) {
        try {
          session = Modular.get<SessionStore>();
        } catch (_) {
          return;
        }
      }
      final activeRideId = await session.readActiveRideId();
      if (activeRideId == null || activeRideId.trim().isEmpty) return;

      TrackRepository? trackRepository = widget.trackRepository;
      if (trackRepository == null) {
        try {
          trackRepository = Modular.get<TrackRepository>();
        } catch (_) {
          return;
        }
      }
      final result = await trackRepository.fetchRideResult(activeRideId.trim());
      await result.fold(
        (failure) async {
          final failureMessage = failure.message.toLowerCase();
          if ((failure is ServerFailure && failure.statusCode == 404) ||
              failureMessage.contains('not found') ||
              failureMessage.contains('incomplete')) {
            await session?.saveActiveRideId('');
          }
        },
        (snapshot) async {
          if (!mounted) return;
          if (snapshot.isTerminal) {
            await session?.saveActiveRideId('');
            return;
          }
          if (mounted) {
            unawaited(
              context.pushNamed(ActiveRideRoutes.trackDriver, extra: snapshot),
            );
          }
        },
      );
    } catch (_) {}
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
    final isAuthenticated = context.select<SessionBloc, bool>(
      (bloc) => bloc.state.isAuthenticated,
    );
    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      builder: (context, state) {
        if (isAuthenticated && state.isLoading && state.places.isNotEmpty) {
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

        return SavedPlaceQuickActions(
          places: isAuthenticated ? state.places : const [],
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

    return BlocBuilder<BookingBloc, BookingState>(
      bloc: _bookingBloc,
      builder: (context, _) {
        if (_hasBlockingBooking()) return const SizedBox.shrink();
        return BlocBuilder<BookingDraftCubit, BookingDraftState>(
          buildWhen: (previous, current) => previous.draft != current.draft,
          builder: (context, state) {
            final draft = state.draft;
            if (draft == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PendingBookingBanner(
                isAuthenticated: isAuthenticated,
                destinationName: draft.destination.name,
                onContinue: () => unawaited(_continuePendingBooking(draft)),
                onDismiss: () =>
                    BlocProvider.of<BookingDraftCubit>(context).clear(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _continuePendingBooking(BookingDraft draft) async {
    if (!await _canStartOrContinueBooking() || !mounted) return;
    _isNavigationInFlight = true;
    try {
      final pickupAddress = draft.pickupAddress;
      final position = LocationService.lastPosition;
      BlocProvider.of<BookingDraftCubit>(context).clear();
      await context.pushNamed(
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
      );
    } finally {
      _isNavigationInFlight = false;
    }
  }

  Widget _buildHeader() {
    return const AppPageHeader(title: 'EasyRide', subtitle: 'Where to today?');
  }

  Widget _buildRecentRideHistoryHeader() {
    return Semantics(
      header: true,
      child: Text(
        'RECENT ACTIVITY',
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _buildRecentRideHistoryList() {
    final isGuest = context.select<SessionBloc, bool>((bloc) {
      final sessionState = bloc.state;
      return !sessionState.isAuthenticated;
    });

    return BlocBuilder<RideHistoryBloc, RideHistoryState>(
      builder: (context, state) {
        if (isGuest) return const RecentRideHistoryEmptyState(isGuest: true);
        if (state is RideHistoryLoading && state.hasExistingRides) {
          final itemCount = state.existingRideCount
              .clamp(1, _recentRideHistoryPreviewLimit)
              .toInt();
          return Skeletonizer.zone(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 54,
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              itemBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Bone.circle(size: 40),
                    SizedBox(width: 14),
                    Expanded(child: Bone.multiText(lines: 2, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is RideHistoryError) {
          return _buildRecentRideHistoryError(state);
        }
        if (state is! RideHistoryLoaded) {
          return RecentRideHistoryEmptyState(isGuest: isGuest);
        }
        final seenDestinations = <String>{};
        final recentRides = <RideHistory>[];
        for (final ride in state.past) {
          final destinationKey = ride.destination.trim().toLowerCase();
          if (destinationKey.isEmpty || seenDestinations.add(destinationKey)) {
            recentRides.add(ride);
          }
          if (recentRides.length >= _recentRideHistoryPreviewLimit) {
            break;
          }
        }
        if (recentRides.isEmpty) {
          return RecentRideHistoryEmptyState(isGuest: isGuest);
        }
        return RecentRideHistoryPreview(
          rides: recentRides,
          onRideTap: (ride) => unawaited(
            context.pushNamed(RideHistoryRoutes.rideDetails, extra: ride),
          ),
        );
      },
    );
  }

  Widget _buildRecentRideHistoryError(RideHistoryError state) {
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return const SizedBox.shrink();
    }
    final title = switch (state.failureKind) {
      RideHistoryFailureKind.connection => 'Connection error',
      RideHistoryFailureKind.server => 'Server error',
      RideHistoryFailureKind.other => 'Could not load recent activity',
    };
    return AppRetryErrorView(
      title: title,
      message: state.message,
      actionLabel: 'Retry activity',
      icon: state.failureKind == RideHistoryFailureKind.connection
          ? LucideIcons.wifi_off
          : LucideIcons.circle_alert,
      onRetry: _loadRecentRideHistory,
    );
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
        HomeRoutes.addCategory,
        extra: {'place': selectedPlace},
      );
      if (newPlace != null && mounted) {
        await cubit.addPlace(newPlace);
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

    SessionStore? session = widget.sessionService;
    if (session == null) {
      try {
        session = Modular.get<SessionStore>();
      } catch (_) {
        // Ride-history fallback remains available if session storage is absent.
      }
    }

    String? activeRideId;
    try {
      activeRideId = await session?.readActiveRideId();
    } catch (_) {}
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
      builder: (dialogContext) {
        final colors = dialogContext.colorScheme;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: colors.outlineVariant),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.car, size: 20, color: colors.onSurface),
          ),
          title: Text(
            'Active Ride in Progress',
            textAlign: TextAlign.center,
            style: dialogContext.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          content: Text(
            'You already have an active trip with $driverName. Please complete or cancel your ongoing ride before booking another.',
            textAlign: TextAlign.center,
            style: dialogContext.textStyles.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style:
                  TextButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.focused)
                          ? colors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                  ),
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _resumeActiveRide();
              },
              style:
                  FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    elevation: 0,
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.focused)
                          ? colors.onPrimary.withValues(alpha: 0.16)
                          : Colors.transparent,
                    ),
                  ),
              child: const Text('Resume Trip'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final colors = context.colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      label: 'Search for a destination',
      hint: 'Opens destination search',
      child: Hero(
        tag: 'search_bar_field',
        child: Material(
          color: colors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            enableFeedback: false,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? colors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            onTap: () => unawaited(_openDestinationFlow()),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 15,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: colors.onSurface, size: 19),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: BlocSelector<HomeCubit, HomeState, List<String>>(
                      selector: (state) {
                        if (state.nearbyPlaceNames.isNotEmpty) {
                          return state.nearbyPlaceNames;
                        }
                        if (state.recentLocations.isEmpty) {
                          return const [];
                        }
                        return state.recentLocations
                            .map((location) => location.title)
                            .toList(growable: false);
                      },
                      builder: (context, suggestions) =>
                          HomeDestinationSearchHint(suggestions: suggestions),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.arrow_right,
                    color: colors.onSurfaceVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        await _showActiveRideBlockedDialog();
      } finally {
        _isNavigationInFlight = false;
      }
      return false;
    }
    if (_hasBlockingBooking()) {
      _isNavigationInFlight = true;
      try {
        await _showActiveBookingBlockedDialog();
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

  Future<void> _showActiveBookingBlockedDialog() async {
    final bookingState = _bookingBloc.state;
    final activeSearch = _bookingBloc.activeDriverSearch;
    final isMatchedOrRecovered =
        bookingState is BookingDriverMatched ||
        bookingState is BookingRideRecovered;
    final isRecoveryFailure = bookingState is BookingSessionRecoveryFailure;
    final isRecovering = bookingState is BookingSessionRecoveryInProgress;

    final String title;
    final String content;
    final IconData icon;
    final String? primaryLabel;
    VoidCallback? primaryAction;

    if (isMatchedOrRecovered) {
      title = 'Driver Accepted Your Trip';
      content = 'Your driver has already accepted your ride. Please resume or complete your ongoing trip before booking another.';
      icon = LucideIcons.car;
      primaryLabel = 'Resume Trip';
      final String? matchedRideId = switch (bookingState) {
        BookingDriverMatched(:final rideId) => rideId,
        BookingRideRecovered(:final rideId) => rideId,
        _ => null,
      };
      primaryAction = () {
        final trimmed = matchedRideId?.trim() ?? '';
        if (trimmed.isNotEmpty) {
          unawaited(
            context.pushNamed(ActiveRideRoutes.trackDriver, extra: trimmed),
          );
        } else {
          _resumeActiveRide();
        }
      };
    } else if (isRecoveryFailure) {
      title = 'Booking Request in Progress';
      content = 'We are still confirming your active ride request. Retry checking its status before booking another.';
      icon = LucideIcons.circle_alert;
      primaryLabel = 'Retry';
      primaryAction = () => _bookingBloc.add(const RestoreActiveBookingEvent());
    } else if (isRecovering) {
      title = 'Booking Request in Progress';
      content = 'We are checking your current ride request. Please wait a moment before booking another.';
      icon = LucideIcons.clock;
      primaryLabel = activeSearch != null ? 'View Request' : null;
      primaryAction = activeSearch == null
          ? null
          : () => unawaited(_openActiveDriverSearch(activeSearch));
    } else {
      final destinationName = activeSearch?.trip.destination.name.trim() ?? '';
      title = 'Booking Request in Progress';
      content = destinationName.isNotEmpty
          ? 'You already have a ride request to $destinationName waiting for a driver. View or cancel it before booking another.'
          : 'You already have a ride request waiting for a driver. Please wait for a response or cancel it before booking another.';
      icon = LucideIcons.clock;
      primaryLabel = activeSearch != null ? 'View Request' : null;
      primaryAction = activeSearch == null
          ? null
          : () => unawaited(_openActiveDriverSearch(activeSearch));
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.colorScheme;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: colors.outlineVariant),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isRecoveryFailure ? colors.error : colors.onSurface,
            ),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: dialogContext.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          content: Text(
            content,
            textAlign: TextAlign.center,
            style: dialogContext.textStyles.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style:
                  TextButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.focused)
                          ? colors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                  ),
              child: const Text('Dismiss'),
            ),
            if (primaryLabel != null && primaryAction != null)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  primaryAction?.call();
                },
                style:
                    FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 0,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.onPrimary.withValues(alpha: 0.16)
                            : Colors.transparent,
                      ),
                    ),
                child: Text(primaryLabel),
              ),
          ],
        );
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
    if (place.hasLocation) {
      _isNavigationInFlight = true;
      try {
        final syntheticPlace = Place(
          id: 'saved_${place.label.toLowerCase().replaceAll(' ', '_')}',
          name: place.label,
          fullAddress: place.savedAddress ?? place.label,
          latitude: place.latitude!,
          longitude: place.longitude!,
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

  Future _showChipOptions(int index, String label) async {
    if (!await ensureSavedPlaceAuthentication(context) || !mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = sheetContext.colorScheme;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.pagePadding,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sheetContext.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Divider(
                  height: 1,
                  color: colors.outlineVariant.withValues(alpha: 0.7),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.focused)
                          ? colors.error.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      if (!mounted) return;
                      await BlocProvider.of<SavedPlacesCubit>(context)
                          .removePlace(index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppLayout.pagePadding,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.trash_2,
                              color: colors.error,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Remove shortcut',
                            style: sheetContext.textStyles.bodyLarge?.copyWith(
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }
}

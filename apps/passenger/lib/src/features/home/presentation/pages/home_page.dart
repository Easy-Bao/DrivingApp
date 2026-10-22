import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
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
  String? _serverErrorMessage;

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
            setState(() => _serverErrorMessage = state.errorMessage);
          },
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (_, current) => current is GuestSession,
          listener: (context, _) =>
              BlocProvider.of<SavedPlacesCubit>(context).clear(),
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
        body: Column(
          children: [
            if (_serverErrorMessage != null)
              AppStatusBanner(
                isVisible: true,
                message: _serverErrorMessage!,
                tone: AppStatusBannerTone.error,
                actionLabel: 'Dismiss',
                onAction: () => setState(() => _serverErrorMessage = null),
              ),
            Expanded(
              child: SafeArea(
                top: _serverErrorMessage == null,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.pageMaxWidth,
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppLayout.pagePadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildSearchBar(),
                              _buildPendingBookingBanner(),
                              _buildActiveBookingBanner(),
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

        return SavedPlaceQuickActions(
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
  }

  Widget _buildActiveBookingBanner() {
    return BlocBuilder<BookingBloc, BookingState>(
      bloc: _bookingBloc,
      builder: (context, state) {
        final activeSearch = _bookingBloc.activeDriverSearch;
        final isSearching =
            state is BookingSearching || state is BookingOffersReceived;
        final isExpired = state is BookingFailure && state.isRequestExpired;
        final isRecovering = state is BookingSessionRecoveryInProgress;
        final recoveryFailed = state is BookingSessionRecoveryFailure;
        final recoveredRide = state is BookingRideRecovered;
        if (!isSearching &&
            !isExpired &&
            !isRecovering &&
            !recoveryFailed &&
            !recoveredRide) {
          return const SizedBox.shrink();
        }

        final colors = context.colorScheme;
        final String title;
        final String subtitle;
        if (state is BookingRideRecovered) {
          title = 'Your driver accepted';
          subtitle = 'Resume your trip to view the driver and route.';
        } else if (state is BookingFailure && state.isRequestExpired) {
          title = 'Your ride request expired';
          subtitle = 'Review your route and request another driver.';
        } else if (state is BookingSearching && state.sessionId == null) {
          title = 'Sending your request';
          subtitle =
              activeSearch?.trip.destination.name ?? 'Confirming request';
        } else if (state is BookingSessionRecoveryFailure) {
          title = 'Unable to refresh your request';
          subtitle = state.message;
        } else if (state is BookingSessionRecoveryInProgress) {
          title = state.sessionId.isEmpty
              ? 'Sending your request'
              : 'Checking your active request';
          subtitle = 'Your trip details will stay saved while we reconnect.';
        } else {
          title = 'Searching for a driver';
          subtitle =
              activeSearch?.trip.destination.name ?? 'Your saved trip request';
        }

        final requestId = state.publicBookingReference;
        final String actionLabel;
        final VoidCallback? onPressed;
        if (state is BookingRideRecovered) {
          actionLabel = 'Resume trip';
          onPressed = () => unawaited(_resumeActiveRideById());
        } else if (state is BookingSessionRecoveryFailure) {
          actionLabel = 'Retry';
          onPressed = () => _bookingBloc.add(const RestoreActiveBookingEvent());
        } else if (state is BookingSessionRecoveryInProgress) {
          actionLabel = 'Checking';
          onPressed = null;
        } else {
          actionLabel = 'Continue';
          onPressed = activeSearch == null
              ? null
              : () => unawaited(_canStartOrContinueBooking());
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, 8, 12),
            decoration: BoxDecoration(
              color: colors.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.secondaryContainer),
            ),
            child: Row(
              children: [
                Icon(
                  state is BookingRideRecovered
                      ? LucideIcons.car_front
                      : LucideIcons.route,
                  size: 20,
                  color: colors.onSurface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (requestId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        TripReference(
                          id: requestId,
                          label: 'Booking ID',
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, AppSize.minimumTouchTarget),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
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
    return const AppPageHeader(
      title: 'EasyRide',
      subtitle: 'Ready to ride today?',
    );
  }

  Widget _buildRecentRideHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recent activity', style: context.textStyles.titleLarge),
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

  Widget _buildRecentRideHistoryError() {
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return const SizedBox.shrink();
    }
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
    } catch (_) {
      // Fall back to the latest active ride from history.
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Active Ride in Progress',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: dialogContext.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'You already have an active trip with $driverName. Please complete or cancel your ongoing ride before booking another.',
          style: TextStyle(
            color: dialogContext.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
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
        onTap: () => unawaited(_openDestinationFlow()),
        child: Hero(
          tag: 'search_bar_field',
          child: Material(
            color: context.colorScheme.surface.withValues(alpha: 0),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colorScheme.outlineVariant),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    color: context.colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: HomeDestinationSearchHint()),
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
    final activeSearch = _bookingBloc.activeDriverSearch;
    if (activeSearch != null) {
      _isNavigationInFlight = true;
      try {
        final trip = activeSearch.trip;
        if (!mounted) return false;
        await context.pushNamed(
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
        );
      } finally {
        _isNavigationInFlight = false;
      }
      return false;
    }
    return mounted;
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
    await BlocProvider.of<SavedPlacesCubit>(context).loadPlaces();
  }

  Future _showChipOptions(int index, String label) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: sheetContext.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sheetContext.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.colorScheme.outlineVariant,
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
                    color: sheetContext.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: sheetContext.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Icon(
                  LucideIcons.trash_2,
                  color: sheetContext.colorScheme.error,
                  size: 20,
                ),
                title: Text(
                  'Remove shortcut',
                  style: TextStyle(
                    color: sheetContext.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (!mounted) return;
                  await BlocProvider.of<SavedPlacesCubit>(context)
                      .removePlace(index);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

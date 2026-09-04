import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/navigation/passenger_navigation_observer.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_state.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_state.dart';
import 'package:passenger/src/features/home/presentation/widgets/home_location_row_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/pending_booking_banner_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/public_driver_summary_card_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_empty_state_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_preview_widget.dart';
import 'package:passenger/src/features/home/presentation/widgets/saved_place_quick_actions_widget.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const HomePage({super.key}) extends StatefulWidget {
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
    return BlocListener<LocationAccessCubit, LocationAccessViewState>(
      listener: _handleLocationAccess,
      child: Scaffold(
        backgroundColor: context.canvasColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 12),
                        _buildLocationRow(),
                        const SizedBox(height: 24),
                        _buildSearchBar(),
                        _buildPendingBookingBanner(),
                        _buildPublicDriverSummary(),
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
    _bookingBloc = Modular.get<BookingBloc>();
    _homeCubit = BlocProvider.of<HomeCubit>(context, listen: false);
    _routePopSubscription = passengerNavigationObserver.routePopEvents.listen(
      (_) => _refreshLocationSnapshot(),
    );
    _lifecycleSubscription = Modular.get<AppLifecycleCoordinator>().changes
        .listen((status) {
          if (status == AppLifecycleStatus.foreground) {
            _refreshLocationSnapshot();
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadSavedPlaces());
      _loadRecentRideHistory();
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

  Widget _buildPublicDriverSummary() {
    return BlocBuilder<PublicDriverSummaryCubit, PublicDriverSummaryState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.summaries != current.summaries,
      builder: (context, state) {
        if (state.summaries.isEmpty || state.isLoading) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PublicDriverSummaryCardWidget(summaries: state.summaries),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EasyRide',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
                letterSpacing: -1.5,
              ),
            ),
            Text(
              'Ready to ride today?',
              style: TextStyle(
                fontSize: 16,
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
      builder: (context, accessState) {
        return BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (prev, curr) =>
              prev.currentAddress != curr.currentAddress ||
              prev.isLoading != curr.isLoading ||
              prev.locationErrorMessage != curr.locationErrorMessage,
          builder: (context, homeState) {
            return HomeLocationRowWidget(
              isAccessChecking: accessState is LocationAccessChecking,
              hasLocationAccess: accessState is LocationAccessReady,
              isAddressLoading: homeState.isLoading,
              currentAddress: homeState.currentAddress,
              locationErrorMessage: homeState.locationErrorMessage,
              onRequestLocation: _showLocationPrompt,
              onRetryAddress: () => unawaited(
                BlocProvider.of<HomeCubit>(context).refreshCurrentLocation(),
              ),
            );
          },
        );
      },
    );
  }

  void _showLocationPrompt() {
    unawaited(BlocProvider.of<LocationAccessCubit>(context).enable());
  }

  Widget _buildRecentRideHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        if (context.select<SessionBloc, bool>(
          (bloc) => bloc.state.isAuthenticated,
        ))
          TextButton(
            onPressed: () => context.goNamed(RideHistoryRoutes.rideHistory),
            child: Text(
              'View all',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
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

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(36),
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
                Text(
                  'Search destination',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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

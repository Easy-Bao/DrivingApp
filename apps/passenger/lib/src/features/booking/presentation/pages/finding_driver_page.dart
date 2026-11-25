import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/core/location/live_map_bloc.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/nearby_drivers/nearby_drivers_cubit.dart';
import 'package:passenger/src/features/booking/presentation/widgets/cancel_booking_dialog.dart';
import 'package:passenger/src/features/booking/presentation/widgets/driver_dropdown_card.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_availability_error_panel.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_nearby_panel.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_nearest_panel.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_no_driver_panel.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_searching_panel.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/home/home_routes.dart';

bool shouldRebuildDriverDiscoveryOverlay(
  BookingState previous,
  BookingState current,
) {
  return (previous is NearestDriverFound) != (current is NearestDriverFound);
}

bool shouldStartFindingDriverHomeNavigation({
  required bool isMounted,
  required bool isNavigationInFlight,
}) => isMounted && !isNavigationInFlight;

class FindingDriverPage extends StatelessWidget {
  const FindingDriverPage({
    super.key,

    required this.fare,
    this.baseFare,
    this.tipAmount,
    required this.destination,
    required this.distance,
    required this.duration,
    this.distanceKm,
    this.durationMinutes,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.passengerNote = '',
    required this.profileRepository,
    required this.driverRepository,
    required this.lifecycleCoordinator,
    required this.bookingBloc,
    required this.liveMapBloc,
  });

  final double fare;
  final double? baseFare;
  final int? tipAmount;
  final Place destination;
  final String distance;
  final String duration;
  final double? distanceKm;
  final double? durationMinutes;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String passengerNote;
  final DriverProfileRepository profileRepository;
  final DriverRepository driverRepository;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final BookingBloc bookingBloc;
  final LiveMapBloc liveMapBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookingBloc>.value(value: bookingBloc),
        if (pickupLatitude != null && pickupLongitude != null)
          BlocProvider<NearbyDriversCubit>(
            create: (_) => NearbyDriversCubit(
              repository: driverRepository,
              lifecycleCoordinator: lifecycleCoordinator,
              latitude: pickupLatitude!,
              longitude: pickupLongitude!,
            ),
          ),
        BlocProvider<LiveMapBloc>(create: (_) => liveMapBloc),
      ],
      child: FindingDriverPageContent(
        fare: fare,
        baseFare: baseFare,
        tipAmount: tipAmount,
        destination: destination,
        distance: distance,
        duration: duration,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        pickupAddress: pickupAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        passengerNote: passengerNote,
        profileRepository: profileRepository,
      ),
    );
  }
}

class FindingDriverPageContent extends StatefulWidget {
  const FindingDriverPageContent({
    super.key,

    required this.fare,
    this.baseFare,
    this.tipAmount,
    required this.destination,
    required this.distance,
    required this.duration,
    this.distanceKm,
    this.durationMinutes,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.passengerNote = '',
    required this.profileRepository,
  });

  final double fare;
  final double? baseFare;
  final int? tipAmount;
  final Place destination;
  final String distance;
  final String duration;
  final double? distanceKm;
  final double? durationMinutes;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String passengerNote;
  final DriverProfileRepository profileRepository;

  @override
  State<FindingDriverPageContent> createState() =>
      _FindingDriverPageContentState();
}

class _FindingDriverPageContentState() extends State<FindingDriverPageContent> {
  final GlobalKey _sheetKey = GlobalKey();
  AppMapController? _mapController;
  Widget? _cachedMap;
  bool _mapLoaded = false;
  bool _focusScheduled = false;
  EdgeInsets? _lastViewportPadding;
  DriverModel? _selectedDriver;
  List<DriverModel> _nearbyDrivers = [];
  bool _isLeaving = false;
  bool _isConfirmingCancel = false;
  bool _isReturningHome = false;
  String? _driverSearchError;
  String? _acceptingOfferId;
  bool _locationUnavailable = false;
  bool _isViewingDriverProfile = false;

  ({double latitude, double longitude})? get _pickupCoordinate {
    final latitude = widget.pickupLatitude;
    final longitude = widget.pickupLongitude;
    if (latitude == null || longitude == null) return null;
    return (latitude: latitude, longitude: longitude);
  }

  double? get _effectiveDistanceKm =>
      widget.distanceKm ??
      double.tryParse(widget.distance.replaceAll(RegExp(r'[^0-9.]'), ''));

  double? get _effectiveDurationMinutes =>
      widget.durationMinutes ??
      double.tryParse(widget.duration.replaceAll(RegExp(r'[^0-9.]'), ''));

  BidSessionTrip _tripMetadata() => BidSessionTrip(
    fare: widget.fare,
    destination: widget.destination,
    distance: widget.distance,
    duration: widget.duration,
    pickupAddress: widget.pickupAddress,
    passengerNote: widget.passengerNote,
  );

  List<DriverModel> _uniqueNearbyDrivers(NearestDriverFound state) {
    final byId = <String, DriverModel>{state.driver.id: state.driver};
    for (final driver in state.nearbyDrivers) {
      byId[driver.id] = driver;
    }
    final drivers = byId.values.toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return drivers;
  }

  @override
  void initState() {
    super.initState();
    final pickup = _pickupCoordinate;
    if (pickup == null) {
      _locationUnavailable = true;
      return;
    }
    final bookingBloc = BlocProvider.of<BookingBloc>(context);
    final currentState = bookingBloc.state;
    final isExpiredRequest =
        currentState is BookingFailure && currentState.isRequestExpired;
    if (!bookingBloc.hasActiveDriverSearch && !isExpiredRequest) {
      bookingBloc.add(
        StartNearbyDriverSearchEvent(
          trip: _tripMetadata(),
          pickupLat: pickup.latitude,
          pickupLng: pickup.longitude,
          distanceKm: _effectiveDistanceKm,
          durationMinutes: _effectiveDurationMinutes,
        ),
      );
    } else if (currentState is BookingSearching ||
        currentState is BookingOffersReceived ||
        (currentState is BookingFailure && currentState.isDriverDeclined)) {
      BlocProvider.of<NearbyDriversCubit>(context).start();
    }
  }

  List<DriverModel> _currentNearbyDrivers(BuildContext context) {
    final bookingState = BlocProvider.of<BookingBloc>(context).state;
    if (bookingState is BookingFindingNearbyDrivers) {
      return bookingState.drivers;
    }
    return BlocProvider.of<NearbyDriversCubit>(context).state.drivers;
  }

  void _showDriverProfile(DriverModel driver) {
    if (!mounted) return;
    setState(() {
      _selectedDriver = driver;
      _isViewingDriverProfile = true;
    });
  }

  void _hideDriverProfile() {
    if (!mounted) return;
    setState(() => _isViewingDriverProfile = false);
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    _mapLoaded = false;
    _lastViewportPadding = null;
  }

  void _onMapLoaded() {
    final controller = _mapController;
    final pickup = _pickupCoordinate;
    if (!mounted || controller == null || pickup == null) return;
    _mapLoaded = true;
    BlocProvider.of<LiveMapBloc>(context).add(
      InitializeMapEvent(
        controller: controller,
        defaultLat: pickup.latitude,
        defaultLng: pickup.longitude,
        routeColor: context.colorScheme.onSurface,
      ),
    );
    _syncNearbyDriverPins(_currentNearbyDrivers(context));
    _schedulePickupFocus();
  }

  void _syncNearbyDriverPins(List<DriverModel> drivers) {
    final pickup = _pickupCoordinate;
    if (pickup == null) return;
    BlocProvider.of<LiveMapBloc>(context).add(
      ReplaceMapMarkersEvent(
        markers: [
          AddMapMarkerEvent(
            lat: pickup.latitude,
            lng: pickup.longitude,
            isOrigin: true,
          ),
          for (final driver in drivers)
            AddMapMarkerEvent(
              lat: driver.lat,
              lng: driver.lng,
              color: AppPalette.obsidian,
            ),
        ],
      ),
    );
    _lastViewportPadding = null;
    _schedulePickupFocus();
  }

  void _schedulePickupFocus() {
    if (_focusScheduled) return;
    _focusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusScheduled = false;
      if (mounted) unawaited(_focusPickup());
    });
  }

  Future<void> _focusPickup() async {
    final controller = _mapController;
    final pickup = _pickupCoordinate;
    final sheetHeight = _sheetKey.currentContext?.size?.height;
    if (!_mapLoaded ||
        controller == null ||
        pickup == null ||
        sheetHeight == null) {
      return;
    }
    final insets = EdgeInsets.fromLTRB(
      24,
      MediaQuery.paddingOf(context).top + 64,
      24,
      sheetHeight + 24,
    );
    if (_lastViewportPadding == insets) return;
    _lastViewportPadding = insets;
    try {
      final drivers = _currentNearbyDrivers(context);
      if (drivers.isEmpty) {
        await MapProvider.moveCamera(
          controller,
          pickup.latitude,
          pickup.longitude,
          zoom: 14.5,
          viewportPadding: insets,
          animate: false,
        );
      } else {
        await MapProvider.fitBounds(
          controller,
          [
            LatLng(pickup.latitude, pickup.longitude),
            for (final driver in drivers) LatLng(driver.lat, driver.lng),
          ],
          viewportPadding: insets,
          maxZoom: 14.5,
        );
      }
    } catch (_) {
      if (mounted && controller == _mapController) _lastViewportPadding = null;
    }
  }

  void _startDirectBooking(DriverModel driver) {
    final pickup = _pickupCoordinate;
    if (pickup == null) return;
    final pickupLat = pickup.latitude;
    final pickupLng = pickup.longitude;

    final distanceNum = _effectiveDistanceKm;
    final durationNum = _effectiveDurationMinutes;
    if (distanceNum == null || durationNum == null) return;

    setState(() {
      _selectedDriver = null;
      _isViewingDriverProfile = false;
    });

    BlocProvider.of<BookingBloc>(context).add(
      StartDirectBookingEvent(
        targetDriver: driver,
        trip: _tripMetadata(),
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        distanceKm: distanceNum,
        durationMinutes: durationNum,
      ),
    );
  }

  Widget _buildNearbyDriversPanel({
    required double fare,
    List<BookingOffer> offers = const [],
    bool isSendingRequest = false,
    bool isChoosingDriver = false,
    String? notice,
    String? refreshError,
    DriverModel? requestedDriver,
    NearbyDriversState? availabilityOverride,
  }) {
    Widget buildPanel(
      BuildContext context,
      NearbyDriversState availability, {
      required VoidCallback onRetry,
    }) {
      return FindingDriverNearbyPanel(
        availability: availability,
        offers: offers,
        fare: fare,
        isChoosingDriver: isChoosingDriver,
        notice: notice,
        onSelectDriver: _startDirectBooking,
        isSendingRequest: isSendingRequest,
        refreshError: refreshError,
        requestedDriver: requestedDriver,
        onRetry: onRetry,
        onAcceptOfferPressed: (offer) {
          if (_isLeaving || _acceptingOfferId != null) return;
          setState(() => _acceptingOfferId = offer.offerId);
          BlocProvider.of<BookingBloc>(context).add(
            AcceptBidOfferEvent(
              offerId: offer.offerId,
              driverId: offer.driverId,
              driverName: offer.displayDriverName,
              vehicleType: offer.displayVehicleType,
              plateNumber: offer.displayPlateNumber,
              proposedFare: offer.proposedFare,
              driverRating: offer.ratingLabel,
            ),
          );
        },
        onBackPressed: _returnHome,
        onCancelPressed: _handleCancel,
        acceptingOfferId: _acceptingOfferId,
        isCanceling: _isLeaving,
      );
    }

    if (availabilityOverride != null) {
      return buildPanel(
        context,
        availabilityOverride,
        onRetry: () =>
            BlocProvider.of<BookingBloc>(context)
                .add(const RefreshBookingSessionEvent()),
      );
    }

    return BlocBuilder<NearbyDriversCubit, NearbyDriversState>(
      builder: (context, availability) => buildPanel(
        context,
        availability,
        onRetry: () {
          unawaited(BlocProvider.of<NearbyDriversCubit>(context).refresh());
          BlocProvider.of<BookingBloc>(context)
              .add(const RefreshBookingSessionEvent());
        },
      ),
    );
  }

  void _showNearbyDrivers() {
    final booking = BlocProvider.of<BookingBloc>(context);
    if (booking.hasActiveBooking) return;
    final pickup = _pickupCoordinate;
    if (pickup != null) {
      booking.add(
        StartNearbyDriverSearchEvent(
          trip: _tripMetadata(),
          pickupLat: pickup.latitude,
          pickupLng: pickup.longitude,
          distanceKm: _effectiveDistanceKm,
          durationMinutes: _effectiveDurationMinutes,
        ),
      );
    } else {
      booking.add(const ResetBookingEvent());
      unawaited(BlocProvider.of<NearbyDriversCubit>(context).refresh());
    }
  }

  void _handleCancel() {
    unawaited(_confirmAndCancel());
  }

  Future<void> _confirmAndCancel() async {
    if (_isLeaving || _isConfirmingCancel || _acceptingOfferId != null) return;
    final bookingBloc = BlocProvider.of<BookingBloc>(context);
    final currentState = bookingBloc.state;
    if (currentState is BookingDriverMatched ||
        currentState is BookingRideRecovered) {
      return;
    }

    final shouldConfirm =
        !(currentState is BookingFailure &&
            (currentState.isNoDriverFound || currentState.isRequestExpired));
    if (shouldConfirm) {
      _isConfirmingCancel = true;
      final destinationName =
          bookingBloc.activeDriverSearch?.trip.destination.name ??
          widget.destination.name;
      final confirmed = await showCancelBookingDialog(
        context,
        isActiveRequest: bookingBloc.hasActiveBooking,
        destinationName: destinationName,
      );
      _isConfirmingCancel = false;
      if (!mounted || !confirmed || _isLeaving || _acceptingOfferId != null) {
        return;
      }
      final latestState = bookingBloc.state;
      if (latestState is BookingDriverMatched ||
          latestState is BookingRideRecovered) {
        return;
      }
    }

    setState(() => _isLeaving = true);
    bookingBloc.add(const CancelBookingEvent());
  }

  void _returnHome() {
    if (!shouldStartFindingDriverHomeNavigation(
      isMounted: mounted,
      isNavigationInFlight: _isReturningHome,
    )) {
      return;
    }
    _isReturningHome = true;
    context.goNamed(HomeRoutes.home);
  }

  void _handleNoDriverFound() {
    if (!mounted) return;
    setState(() {
      _driverSearchError = null;
      _isLeaving = false;
      _nearbyDrivers = [];
      _selectedDriver = null;
      _isViewingDriverProfile = false;
    });
  }

  void _retryFindingDriver() {
    final pickup = _pickupCoordinate;
    if (pickup == null) {
      setState(() => _locationUnavailable = true);
      return;
    }

    setState(() {
      _driverSearchError = null;
      _isLeaving = false;
      _selectedDriver = null;
      _isViewingDriverProfile = false;
    });
    _showNearbyDrivers();
  }

  @override
  Widget build(BuildContext context) {
    if (_locationUnavailable) {
      return const Scaffold(
        body: Center(child: Text('Your location is unavailable.')),
      );
    }
    final pickup = _pickupCoordinate;
    if (pickup == null) {
      return const Scaffold(
        body: Center(child: Text('Your location is unavailable.')),
      );
    }
    final defaultLat = pickup.latitude;
    final defaultLng = pickup.longitude;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _returnHome();
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: MultiBlocListener(
          listeners: [
            BlocListener<NearbyDriversCubit, NearbyDriversState>(
              listenWhen: (previous, current) =>
                  !listEquals(previous.drivers, current.drivers),
              listener: (context, state) {
                final bookingState = BlocProvider.of<BookingBloc>(context)
                    .state;
                if (bookingState is! NearestDriverFound &&
                    bookingState is! BookingFindingNearbyDrivers) {
                  _syncNearbyDriverPins(state.drivers);
                }
              },
            ),
            BlocListener<BookingBloc, BookingState>(
              listenWhen: (previous, current) {
                if (current is! BookingFindingNearbyDrivers) return false;
                if (previous is! BookingFindingNearbyDrivers) return true;
                return !listEquals(previous.drivers, current.drivers);
              },
              listener: (context, state) {
                if (state is BookingFindingNearbyDrivers) {
                  _syncNearbyDriverPins(state.drivers);
                }
              },
            ),
            BlocListener<BookingBloc, BookingState>(
              listener: (context, state) {
                if (state is BookingFindingNearbyDrivers) {
                  BlocProvider.of<NearbyDriversCubit>(context).stop();
                } else if (state is BookingSearching ||
                    state is BookingOffersReceived) {
                  BlocProvider.of<NearbyDriversCubit>(context).start();
                } else if (state is NearestDriverFound) {
                  final nearbyDrivers = _uniqueNearbyDrivers(state);
                  setState(() {
                    _nearbyDrivers = nearbyDrivers;
                    _selectedDriver =
                        _selectedDriver != null &&
                            nearbyDrivers.any(
                              (driver) => driver.id == _selectedDriver!.id,
                            )
                        ? _selectedDriver
                        : null;
                  });
                  final liveMapBloc = BlocProvider.of<LiveMapBloc>(context);
                  liveMapBloc.add(const ClearMapAnnotationsEvent());
                  liveMapBloc.add(
                    AddMapMarkerEvent(
                      lat: state.pickupLat,
                      lng: state.pickupLng,
                      isOrigin: true,
                    ),
                  );
                  liveMapBloc.add(
                    AddMapMarkerEvent(
                      lat: state.driver.lat,
                      lng: state.driver.lng,
                      color: AppPalette.obsidian,
                      onTap: () {
                        if (!mounted) return;
                        setState(() {
                          _selectedDriver = state.driver;
                          _isViewingDriverProfile = false;
                        });
                      },
                    ),
                  );
                  for (final nearby in nearbyDrivers.take(10)) {
                    if (nearby.id != state.driver.id) {
                      liveMapBloc.add(
                        AddMapMarkerEvent(
                          lat: nearby.lat,
                          lng: nearby.lng,
                          color: AppPalette.obsidian,
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              _selectedDriver = nearby;
                              _isViewingDriverProfile = false;
                            });
                          },
                        ),
                      );
                    }
                  }
                  liveMapBloc.add(
                    FitMapToCoordinatesEvent(
                      coordinates: [
                        LatLng(state.pickupLat, state.pickupLng),
                        ...nearbyDrivers
                            .take(10)
                            .map((driver) => LatLng(driver.lat, driver.lng)),
                      ],
                      maxZoom: 14.5,
                    ),
                  );
                } else if (state is BookingDriverMatched) {
                  unawaited(HapticFeedback.lightImpact());
                  context.pushReplacementNamed(
                    ActiveRideRoutes.trackDriver,
                    extra: state.rideId,
                  );
                } else if (state is BookingFailure) {
                  _acceptingOfferId = null;
                  if (state.isNoDriverFound) {
                    BlocProvider.of<NearbyDriversCubit>(context).stop();
                    _handleNoDriverFound();
                  } else if (state.isRequestExpired) {
                    BlocProvider.of<NearbyDriversCubit>(context).stop();
                    setState(() {
                      _driverSearchError = null;
                      _isLeaving = false;
                    });
                  } else if (state.isDriverDeclined) {
                    final nearbyCubit = BlocProvider.of<NearbyDriversCubit>(
                      context,
                    )..start();
                    unawaited(nearbyCubit.refresh());
                    setState(() {
                      _driverSearchError = state.message;
                      _isLeaving = false;
                    });
                  } else {
                    setState(() {
                      _driverSearchError = state.message;
                      _isLeaving = false;
                    });
                  }
                } else if (state is BookingSessionRecoveryFailure) {
                  setState(() {
                    _acceptingOfferId = null;
                    _isLeaving = false;
                  });
                } else if (state is BookingCanceled) {
                  _acceptingOfferId = null;
                  _returnHome();
                }
              },
            ),
          ],
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600.0;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: context.colorScheme.surfaceContainerHighest,
                      child: _cachedMap ??= MapProvider.buildMapView(
                        latitude: defaultLat,
                        longitude: defaultLng,
                        zoom: 14.5,
                        interactive: true,
                        onMapCreated: _onMapCreated,
                        onMapLoaded: _onMapLoaded,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 600.0 : double.infinity,
                        ),
                        child: BlocBuilder<BookingBloc, BookingState>(
                          buildWhen: shouldRebuildDriverDiscoveryOverlay,
                          builder: (context, state) {
                            final showDriverDiscovery =
                                state is NearestDriverFound;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: _buildTripBackButton(
                                    context,
                                    _returnHome,
                                  ),
                                ),
                                if (showDriverDiscovery &&
                                    _nearbyDrivers.isNotEmpty)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: _nearbyDrivers.map((driver) {
                                        final isSelected =
                                            _selectedDriver?.id == driver.id;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: _NearbyDriverSelectionChip(
                                            driver: driver,
                                            isSelected: isSelected,
                                            onTap: () {
                                              setState(() {
                                                _selectedDriver = driver;
                                                _isViewingDriverProfile = false;
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if (showDriverDiscovery &&
                                    _selectedDriver != null)
                                  DriverDropdownCard(
                                    driver: _selectedDriver!,
                                    isNearestDriver:
                                        _nearbyDrivers.isNotEmpty &&
                                        _selectedDriver!.id ==
                                            _nearbyDrivers.first.id,
                                    isProfileVisible: _isViewingDriverProfile,
                                    onViewFullProfilePressed: () =>
                                        _showDriverProfile(_selectedDriver!),
                                    onProfileBackPressed: _hideDriverProfile,
                                    onSelectDriverPressed: () =>
                                        _startDirectBooking(_selectedDriver!),
                                    onCloseDropdownPressed: () {
                                      setState(() {
                                        _selectedDriver = null;
                                        _isViewingDriverProfile = false;
                                      });
                                    },
                                    profileRepository: widget.profileRepository,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      key: _sheetKey,
                      constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 600.0 : double.infinity,
                      ),
                      child: BlocBuilder<BookingBloc, BookingState>(
                        builder: (context, state) {
                          _schedulePickupFocus();
                          final activeSearch = BlocProvider.of<BookingBloc>(
                            context,
                          ).activeDriverSearch;
                          final activeTrip = activeSearch?.trip;
                          final fare = activeTrip?.fare ?? widget.fare;
                          final destination =
                              activeTrip?.destination ?? widget.destination;
                          final pickupAddress =
                              activeTrip?.pickupAddress ?? widget.pickupAddress;

                          if (state is BookingFailure &&
                              state.isDriverDeclined) {
                            return _buildNearbyDriversPanel(
                              fare: fare,
                              isChoosingDriver: true,
                              notice: state.message,
                            );
                          } else if (state is BookingInitial) {
                            return _buildNearbyDriversPanel(
                              fare: fare,
                              isChoosingDriver: true,
                            );
                          } else if (state is BookingFindingNearbyDrivers) {
                            return _buildNearbyDriversPanel(
                              fare: fare,
                              isChoosingDriver: true,
                              availabilityOverride: NearbyDriversState(
                                drivers: state.drivers,
                                hasLoaded: state.hasLoaded,
                                isLoading: state.isLoading,
                                errorMessage: state.errorMessage,
                              ),
                            );
                          } else if (state is FindingNearestDriver) {
                            return FindingDriverSearchingPanel(
                              message: state.statusMessage,
                              fare: fare,
                              baseFare: widget.baseFare,
                              destination: destination,
                              pickupAddress: pickupAddress,
                              tipAmount: widget.tipAmount,
                              distance: widget.distance,
                              duration: widget.duration,
                              requestCreated: false,
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (state is BookingFailure &&
                              (state.isNoDriverFound ||
                                  state.isRequestExpired)) {
                            final isExpired = state.isRequestExpired;
                            return FindingDriverNoDriverPanel(
                              fare: widget.fare,
                              destination: widget.destination,
                              pickupAddress: pickupAddress,
                              requestExpired: isExpired,
                              onRetryPressed: _retryFindingDriver,
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (_driverSearchError != null &&
                              state is BookingFailure &&
                              !AppNetworkStatusScope.isUnavailableOf(context)) {
                            return FindingDriverAvailabilityErrorPanel(
                              message: _driverSearchError!,
                              fare: widget.fare,
                              destination: widget.destination,
                              onRetryPressed: _retryFindingDriver,
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (state is NearestDriverFound) {
                            if (_selectedDriver != null ||
                                _nearbyDrivers.length <= 1) {
                              return const SizedBox.shrink();
                            }
                            return FindingDriverNearestPanel(
                              state: state,
                              fare: widget.fare,
                              onViewFullProfilePressed: () =>
                                  _showDriverProfile(state.driver),
                              onBookDirectPressed: () =>
                                  _startDirectBooking(state.driver),
                              onSearchAllDriversPressed: _showNearbyDrivers,
                              onCancelRidePressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (state is BookingSearching) {
                            return _buildNearbyDriversPanel(
                              fare: fare,
                              requestedDriver: state.targetDriver,
                              isSendingRequest: state.sessionId == null,
                              refreshError: state.refreshError,
                            );
                          } else if (state is BookingOffersReceived) {
                            return _buildNearbyDriversPanel(
                              fare: fare,
                              requestedDriver: state.targetDriver,
                              offers: state.offers,
                              refreshError: state.refreshError,
                            );
                          } else if (state
                              is BookingSessionRecoveryInProgress) {
                            final requestCreated = state.sessionId.isNotEmpty;
                            return FindingDriverSearchingPanel(
                              message: state.statusMessage,
                              fare: fare,
                              baseFare: widget.baseFare,
                              destination: destination,
                              pickupAddress: pickupAddress,
                              tipAmount: widget.tipAmount,
                              distance: widget.distance,
                              duration: widget.duration,
                              requestCreated: requestCreated,
                              isSendingRequest: !requestCreated,
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (state is BookingSessionRecoveryFailure) {
                            final requestCreated = state.sessionId.isNotEmpty;
                            return FindingDriverSearchingPanel(
                              message: requestCreated
                                  ? 'Unable to refresh your request'
                                  : 'We could not confirm your request yet',
                              fare: fare,
                              baseFare: widget.baseFare,
                              destination: destination,
                              pickupAddress: pickupAddress,
                              tipAmount: widget.tipAmount,
                              distance: widget.distance,
                              duration: widget.duration,
                              requestCreated: requestCreated,
                              isSendingRequest: !requestCreated,
                              animate: false,
                              refreshError: state.message,
                              onRetryPressed: () =>
                                  BlocProvider.of<BookingBloc>(context)
                                      .add(const RestoreActiveBookingEvent()),
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class const _NearbyDriverSelectionChip({
  required this.driver,
  required this.isSelected,
  required this.onTap,
}) extends StatelessWidget {
  final DriverModel driver;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _vehicleIcon {
    final vehicleType = driver.vehicleType.toLowerCase();
    if (vehicleType.contains('suv') || vehicleType.contains('sedan')) {
      return LucideIcons.car_front;
    }
    return LucideIcons.car;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(AppRadius.pill);
    final foregroundColor = isSelected ? scheme.onPrimary : scheme.onSurface;
    final distance = DistanceFormatter.fromKilometers(driver.distanceKm);

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${driver.displayName}, ${driver.vehicleType}, rating ${driver.rating.toStringAsFixed(1)}, $distance away',
      child: Material(
        color: isSelected ? scheme.primary : scheme.surfaceContainerLowest,
        elevation: isSelected ? 1 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? (isSelected ? scheme.onPrimary : scheme.primary).withValues(
                    alpha: isSelected ? 0.16 : 0.12,
                  )
                : Colors.transparent,
          ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSize.minimumTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
              ),
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_vehicleIcon, size: 17, color: foregroundColor),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: isSelected
                              ? scheme.onPrimary
                              : context.semanticColors.rating,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: context.textStyles.labelSmall?.tabular
                              .copyWith(
                                color: foregroundColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          distance,
                          style: context.textStyles.labelSmall?.tabular
                              .copyWith(
                                color: foregroundColor.withValues(alpha: 0.78),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  final colors = context.colorScheme;
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: colors.surfaceContainerLowest,
      elevation: 1,
      shadowColor: colors.onSurface.withValues(alpha: 0.08),
      shape: CircleBorder(side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: 'Back',
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: SizedBox(
            width: AppSize.minimumTouchTarget,
            height: AppSize.minimumTouchTarget,
            child: Center(
              child: Icon(
                LucideIcons.arrow_left,
                size: 19,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

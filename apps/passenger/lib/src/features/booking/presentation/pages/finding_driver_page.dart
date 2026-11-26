import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_availability_error_panel.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_discovery_overlay.dart';
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

double? parseRouteDurationMinutes(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  final hourMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b')
      .firstMatch(normalized);
  final minMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:minutes?|mins?|m)\b')
      .firstMatch(normalized);
  if (hourMatch != null || minMatch != null) {
    final hours = double.tryParse(hourMatch?.group(1) ?? '') ?? 0;
    final minutes = double.tryParse(minMatch?.group(1) ?? '') ?? 0;
    final total = (hours * 60) + minutes;
    return total > 0 ? total : null;
  }
  return double.tryParse(normalized.replaceAll(RegExp(r'[^0-9.]'), ''));
}

double? parseRouteDistanceKm(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  final kmMatch = RegExp(r'(\d+(?:\.\d+)?)\s*km\b').firstMatch(normalized);
  if (kmMatch != null) {
    return double.tryParse(kmMatch.group(1) ?? '');
  }
  final mMatch = RegExp(r'(\d+(?:\.\d+)?)\s*m\b').firstMatch(normalized);
  if (mMatch != null) {
    final meters = double.tryParse(mMatch.group(1) ?? '');
    return meters == null ? null : meters / 1000;
  }
  return double.tryParse(normalized.replaceAll(RegExp(r'[^0-9.]'), ''));
}

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
        if (pickupLatitude case final lat?)
          if (pickupLongitude case final lng?)
            BlocProvider<NearbyDriversCubit>(
              create: (_) => NearbyDriversCubit(
                repository: driverRepository,
                lifecycleCoordinator: lifecycleCoordinator,
                latitude: lat,
                longitude: lng,
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

typedef _DriverPinCoordinate = ({String id, double lat, double lng});

class _FindingDriverPageContentState() extends State<FindingDriverPageContent> {
  final GlobalKey _sheetKey = GlobalKey();
  AppMapController? _mapController;
  Widget? _cachedMap;
  bool _mapLoaded = false;
  bool _focusScheduled = false;
  EdgeInsets? _lastViewportPadding;
  List<_DriverPinCoordinate>? _lastSyncedDriverPins;
  Driver? _selectedDriver;
  List<Driver> _nearbyDrivers = [];
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
      widget.distanceKm ?? parseRouteDistanceKm(widget.distance);

  double? get _effectiveDurationMinutes =>
      widget.durationMinutes ?? parseRouteDurationMinutes(widget.duration);

  BidSessionTrip _tripMetadata() => BidSessionTrip(
    fare: widget.fare,
    destination: widget.destination,
    distance: widget.distance,
    duration: widget.duration,
    pickupAddress: widget.pickupAddress,
    passengerNote: widget.passengerNote,
  );

  List<Driver> _uniqueNearbyDrivers(NearestDriverFound state) {
    final byId = <String, Driver>{state.driver.id: state.driver};
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

  List<Driver> _currentNearbyDrivers(BuildContext context) {
    final bookingState = BlocProvider.of<BookingBloc>(context).state;
    if (bookingState is BookingFindingNearbyDrivers) {
      return bookingState.drivers;
    }
    return BlocProvider.of<NearbyDriversCubit>(context).state.drivers;
  }

  void _showDriverProfile(Driver driver) {
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
    _lastSyncedDriverPins = null;
  }

  void _onMapLoaded() {
    final controller = _mapController;
    final pickup = _pickupCoordinate;
    if (!mounted || controller == null || pickup == null) return;
    _mapLoaded = true;
    _lastSyncedDriverPins = null;
    BlocProvider.of<LiveMapBloc>(context).add(
      InitializeMapEvent(
        controller: controller,
        defaultLat: pickup.latitude,
        defaultLng: pickup.longitude,
        routeColor: context.colorScheme.onSurface,
      ),
    );
    _syncNearbyDriverPins(_currentNearbyDrivers(context), force: true);
    _schedulePickupFocus();
  }

  void _syncNearbyDriverPins(List<Driver> drivers, {bool force = false}) {
    final pickup = _pickupCoordinate;
    if (pickup == null) return;
    final nextCoords = <_DriverPinCoordinate>[
      for (final driver in drivers)
        (id: driver.id, lat: driver.lat, lng: driver.lng),
    ];
    if (!force &&
        _lastSyncedDriverPins != null &&
        listEquals(_lastSyncedDriverPins, nextCoords)) {
      return;
    }
    _lastSyncedDriverPins = nextCoords;
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

  void _startDirectBooking(Driver driver) {
    final pickup = _pickupCoordinate;
    if (pickup == null) return;
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
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
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
    Driver? requestedDriver,
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

  void _handleCancel() => unawaited(_confirmAndCancel());

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
    if (_pickupCoordinate == null) {
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

  void _handleBookingState(BuildContext context, BookingState state) {
    switch (state) {
      case BookingFindingNearbyDrivers():
        BlocProvider.of<NearbyDriversCubit>(context).stop();
      case BookingSearching() || BookingOffersReceived():
        BlocProvider.of<NearbyDriversCubit>(context).start();
      case NearestDriverFound():
        _applyNearestDriverFound(context, state);
      case BookingDriverMatched(:final rideId):
        unawaited(HapticFeedback.lightImpact());
        context.pushReplacementNamed(
          ActiveRideRoutes.trackDriver,
          extra: rideId,
        );
      case BookingRideRecovered(:final rideId):
        unawaited(HapticFeedback.lightImpact());
        context.pushReplacementNamed(
          ActiveRideRoutes.trackDriver,
          extra: rideId,
        );
      case BookingFailure():
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
          final nearbyCubit = BlocProvider.of<NearbyDriversCubit>(context)
            ..start();
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
      case BookingSessionRecoveryFailure():
        setState(() {
          _acceptingOfferId = null;
          _isLeaving = false;
        });
      case BookingCanceled():
        _acceptingOfferId = null;
        _returnHome();
      case BookingInitial() ||
          FindingNearestDriver() ||
          BookingSessionRecoveryInProgress():
        break;
    }
  }

  void _applyNearestDriverFound(
    BuildContext context,
    NearestDriverFound state,
  ) {
    final nearbyDrivers = _uniqueNearbyDrivers(state);
    final currentSelected = _selectedDriver;
    setState(() {
      _nearbyDrivers = nearbyDrivers;
      _selectedDriver =
          currentSelected != null &&
              nearbyDrivers.any((driver) => driver.id == currentSelected.id)
          ? currentSelected
          : null;
    });
    _lastSyncedDriverPins = null;
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
  }

  Widget _buildBottomSheet(BuildContext context, BookingState state) {
    _schedulePickupFocus();
    final activeSearch = BlocProvider.of<BookingBloc>(context)
        .activeDriverSearch;
    final activeTrip = activeSearch?.trip;
    final fare = activeTrip?.fare ?? widget.fare;
    final destination = activeTrip?.destination ?? widget.destination;
    final pickupAddress = activeTrip?.pickupAddress ?? widget.pickupAddress;

    return switch (state) {
      BookingFailure(isDriverDeclined: true) => _buildNearbyDriversPanel(
        fare: fare,
        isChoosingDriver: true,
        notice: state.message,
      ),
      BookingInitial() => _buildNearbyDriversPanel(
        fare: fare,
        isChoosingDriver: true,
      ),
      BookingFindingNearbyDrivers() => _buildNearbyDriversPanel(
        fare: fare,
        isChoosingDriver: true,
        availabilityOverride: NearbyDriversState(
          drivers: state.drivers,
          hasLoaded: state.hasLoaded,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
        ),
      ),
      FindingNearestDriver() => FindingDriverSearchingPanel(
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
      ),
      BookingFailure(:final isNoDriverFound, :final isRequestExpired)
          when isNoDriverFound || isRequestExpired =>
        FindingDriverNoDriverPanel(
          fare: widget.fare,
          destination: widget.destination,
          pickupAddress: pickupAddress,
          requestExpired: isRequestExpired,
          onRetryPressed: _retryFindingDriver,
          onCancelPressed: _handleCancel,
          isCanceling: _isLeaving,
        ),
      BookingFailure() => FindingDriverAvailabilityErrorPanel(
        message: _driverSearchError ?? state.message,
        fare: widget.fare,
        destination: widget.destination,
        onRetryPressed: _retryFindingDriver,
        onCancelPressed: _handleCancel,
        isCanceling: _isLeaving,
      ),
      NearestDriverFound()
          when _selectedDriver != null || _nearbyDrivers.length <= 1 =>
        const SizedBox.shrink(),
      NearestDriverFound() => FindingDriverNearestPanel(
        state: state,
        fare: widget.fare,
        onViewFullProfilePressed: () => _showDriverProfile(state.driver),
        onBookDirectPressed: () => _startDirectBooking(state.driver),
        onSearchAllDriversPressed: _showNearbyDrivers,
        onCancelRidePressed: _handleCancel,
        isCanceling: _isLeaving,
      ),
      BookingSearching() => _buildNearbyDriversPanel(
        fare: fare,
        requestedDriver: state.targetDriver,
        isSendingRequest: state.sessionId == null,
        refreshError: state.refreshError,
      ),
      BookingOffersReceived() => _buildNearbyDriversPanel(
        fare: fare,
        requestedDriver: state.targetDriver,
        offers: state.offers,
        refreshError: state.refreshError,
      ),
      BookingSessionRecoveryInProgress() => FindingDriverSearchingPanel(
        message: state.statusMessage,
        fare: fare,
        baseFare: widget.baseFare,
        destination: destination,
        pickupAddress: pickupAddress,
        tipAmount: widget.tipAmount,
        distance: widget.distance,
        duration: widget.duration,
        requestCreated: state.sessionId.isNotEmpty,
        isSendingRequest: state.sessionId.isEmpty,
        onCancelPressed: _handleCancel,
        isCanceling: _isLeaving,
      ),
      BookingSessionRecoveryFailure() => FindingDriverSearchingPanel(
        message: state.sessionId.isNotEmpty
            ? 'Unable to refresh your request'
            : 'We could not confirm your request yet',
        fare: fare,
        baseFare: widget.baseFare,
        destination: destination,
        pickupAddress: pickupAddress,
        tipAmount: widget.tipAmount,
        distance: widget.distance,
        duration: widget.duration,
        requestCreated: state.sessionId.isNotEmpty,
        isSendingRequest: state.sessionId.isEmpty,
        animate: false,
        refreshError: state.message,
        onRetryPressed: () =>
            BlocProvider.of<BookingBloc>(context)
                .add(const RestoreActiveBookingEvent()),
        onCancelPressed: _handleCancel,
        isCanceling: _isLeaving,
      ),
      BookingDriverMatched() ||
      BookingRideRecovered() ||
      BookingCanceled() => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickupCoordinate;
    if (_locationUnavailable || pickup == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _returnHome,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'Your location is unavailable.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
              listener: _handleBookingState,
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
                        latitude: pickup.latitude,
                        longitude: pickup.longitude,
                        zoom: 14.5,
                        interactive: true,
                        onMapCreated: _onMapCreated,
                        onMapLoaded: _onMapLoaded,
                      ),
                    ),
                  ),
                  FindingDriverDiscoveryOverlay(
                    isWideScreen: isWideScreen,
                    buildWhen: shouldRebuildDriverDiscoveryOverlay,
                    nearbyDrivers: _nearbyDrivers,
                    selectedDriver: _selectedDriver,
                    isViewingDriverProfile: _isViewingDriverProfile,
                    profileRepository: widget.profileRepository,
                    onBackPressed: _returnHome,
                    onSelectNearbyChip: (driver) {
                      setState(() {
                        _selectedDriver = driver;
                        _isViewingDriverProfile = false;
                      });
                    },
                    onViewFullProfile: _showDriverProfile,
                    onHideDriverProfile: _hideDriverProfile,
                    onStartDirectBooking: _startDirectBooking,
                    onCloseDropdown: () {
                      setState(() {
                        _selectedDriver = null;
                        _isViewingDriverProfile = false;
                      });
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      key: _sheetKey,
                      constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 600.0 : double.infinity,
                      ),
                      child: BlocBuilder<BookingBloc, BookingState>(
                        builder: _buildBottomSheet,
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

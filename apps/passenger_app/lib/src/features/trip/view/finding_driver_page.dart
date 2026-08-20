import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/domain/entities/bid_session_trip.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/features/trip/view/widgets/driver_dropdown_card_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/finding_driver_availability_error_panel_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/finding_driver_bids_panel_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/finding_driver_nearest_panel_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/finding_driver_no_driver_panel_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/finding_driver_searching_panel_widget.dart';
import 'package:shared_core/shared_core.dart';

class FindingDriverPage extends StatelessWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String passengerNote;

  const FindingDriverPage({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.passengerNote = '',
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookingBloc>.value(value: Modular.get<BookingBloc>()),
        BlocProvider<LiveMapBloc>.value(value: Modular.get<LiveMapBloc>()),
      ],
      child: FindingDriverPageContent(
        rideType: rideType,
        fare: fare,
        destination: destination,
        distance: distance,
        duration: duration,
        pickupAddress: pickupAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        passengerNote: passengerNote,
      ),
    );
  }
}

class FindingDriverPageContent extends StatefulWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String passengerNote;

  const FindingDriverPageContent({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.passengerNote = '',
  });

  @override
  State<FindingDriverPageContent> createState() =>
      _FindingDriverPageContentState();
}

class _FindingDriverPageContentState extends State<FindingDriverPageContent>
    with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late AnimationController _dotCtrl;
  bool _initialized = false;
  DriverModel? _selectedDriver;
  List<DriverModel> _nearbyDrivers = [];
  bool _isLeaving = false;
  bool _isNoDriverFound = false;
  String? _driverSearchError;
  String? _acceptingOfferId;
  bool _locationUnavailable = false;
  bool _isViewingDriverProfile = false;

  ({double lat, double lng})? get _pickupCoordinate {
    final latitude = widget.pickupLatitude;
    final longitude = widget.pickupLongitude;
    if (latitude == null || longitude == null) return null;
    return (lat: latitude, lng: longitude);
  }

  String _driverMarkerLabel(DriverModel driver) {
    final onboard = driver.onboardPassengerCount;
    return '${driver.displayName}\n★ ${driver.rating.toStringAsFixed(1)} • '
        '${DistanceFormatter.fromKilometers(driver.distanceKm)} • '
        '${onboard == null ? '—' : '$onboard/5'} passengers';
  }

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
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_radarCtrl.repeat());
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    unawaited(_dotCtrl.repeat());

    final pickup = _pickupCoordinate;
    if (pickup == null) {
      _locationUnavailable = true;
      return;
    }
    final lat = pickup.lat;
    final lng = pickup.lng;

    final bookingBloc = BlocProvider.of<BookingBloc>(context);
    if (!bookingBloc.hasActiveDriverSearch) {
      bookingBloc.add(
        LocateNearestDriverEvent(
          pickupLat: lat,
          pickupLng: lng,
          trip: BidSessionTrip(
            rideType: widget.rideType,
            fare: widget.fare,
            destination: widget.destination,
            distance: widget.distance,
            duration: widget.duration,
            pickupAddress: widget.pickupAddress,
            passengerNote: widget.passengerNote,
          ),
        ),
      );
    }
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

  @override
  void dispose() {
    _radarCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  void _onMapCreated(AppMapController controller, BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      final pickup = _pickupCoordinate;
      if (pickup == null) return;
      final lat = pickup.lat;
      final lng = pickup.lng;

      BlocProvider.of<LiveMapBloc>(context).add(
        InitializeMapEvent(
          controller: controller,
          defaultLat: lat,
          defaultLng: lng,
        ),
      );

      BlocProvider.of<LiveMapBloc>(context).add(
        AddMapMarkerEvent(
          lat: lat,
          lng: lng,
          label: 'Pickup point\nDriver will meet you here',
          isOrigin: true,
        ),
      );
    }
  }

  void _startDirectBooking(DriverModel driver) {
    final pickup = _pickupCoordinate;
    if (pickup == null) return;
    final pickupLat = pickup.lat;
    final pickupLng = pickup.lng;

    final distanceNum = double.tryParse(
      widget.distance.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final durationNum = double.tryParse(
      widget.duration.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (distanceNum == null || durationNum == null) return;

    // Once a direct request is sent, the passenger should see the focused
    // waiting state rather than the previously selected driver card.
    setState(() {
      _selectedDriver = null;
      _isViewingDriverProfile = false;
    });

    final tripMetadata = BidSessionTrip(
      rideType: widget.rideType,
      fare: widget.fare,
      destination: widget.destination,
      distance: widget.distance,
      duration: widget.duration,
      pickupAddress: widget.pickupAddress,
      passengerNote: widget.passengerNote,
    );

    BlocProvider.of<BookingBloc>(context).add(
      StartDirectBookingEvent(
        targetDriver: driver,
        trip: tripMetadata,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        distanceKm: distanceNum,
        durationMinutes: durationNum,
      ),
    );
  }

  void _startOpenBooking() {
    final pickup = _pickupCoordinate;
    if (pickup == null) return;
    final pickupLat = pickup.lat;
    final pickupLng = pickup.lng;

    final distanceNum = double.tryParse(
      widget.distance.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final durationNum = double.tryParse(
      widget.duration.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (distanceNum == null || durationNum == null) return;

    final tripMetadata = BidSessionTrip(
      rideType: widget.rideType,
      fare: widget.fare,
      destination: widget.destination,
      distance: widget.distance,
      duration: widget.duration,
      pickupAddress: widget.pickupAddress,
      passengerNote: widget.passengerNote,
    );

    BlocProvider.of<BookingBloc>(context).add(
      StartOpenBookingEvent(
        trip: tripMetadata,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        distanceKm: distanceNum,
        durationMinutes: durationNum,
      ),
    );
  }

  void _handleCancel() {
    if (_isLeaving || _acceptingOfferId != null) return;
    setState(() => _isLeaving = true);
    BlocProvider.of<BookingBloc>(context).add(const CancelBookingEvent());
  }

  void _returnHome() {
    if (!mounted) return;
    context.goNamed(HomeRoutes.home);
  }

  void _handleNoDriverFound() {
    if (!mounted) return;
    setState(() {
      _isNoDriverFound = true;
      _driverSearchError = null;
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
      _isNoDriverFound = false;
      _driverSearchError = null;
      _isLeaving = false;
    });
    BlocProvider.of<BookingBloc>(context).add(
      LocateNearestDriverEvent(
        pickupLat: pickup.lat,
        pickupLng: pickup.lng,
        trip: BidSessionTrip(
          rideType: widget.rideType,
          fare: widget.fare,
          destination: widget.destination,
          distance: widget.distance,
          duration: widget.duration,
          pickupAddress: widget.pickupAddress,
          passengerNote: widget.passengerNote,
        ),
      ),
    );
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
    final defaultLat = pickup.lat;
    final defaultLng = pickup.lng;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _returnHome();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: BlocListener<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is NearestDriverFound) {
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
                  lat: state.driver.lat,
                  lng: state.driver.lng,
                  label: _driverMarkerLabel(state.driver),
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
                      label: _driverMarkerLabel(nearby),
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
              final match = state.matchResult;
              final navExtra = <String, dynamic>{
                'rideType': widget.rideType,
                'destination': widget.destination,
                'distance': widget.distance,
                'duration': widget.duration,
                'pickupAddress': widget.pickupAddress,
                'driverId': match.driverId,
                'driverName': match.driverName,
                'driverRating': match.driverRating,
                'vehicleType': match.vehicleType,
                'plateNumber': match.plateNumber,
                'fare': match.proposedFare,
                'createdRide': state.createdRide,
              };
              context.pushReplacementNamed(
                TripRoutes.driverMatched,
                extra: navExtra,
              );
            } else if (state is BookingFailure) {
              _acceptingOfferId = null;
              if (state.isNoDriverFound) {
                _handleNoDriverFound();
              } else {
                setState(() {
                  _driverSearchError = state.message;
                  _isNoDriverFound = false;
                });
              }
            } else if (state is BookingCanceled) {
              _acceptingOfferId = null;
              _returnHome();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600.0;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.neutralColor,
                      child: MapProvider.buildMapView(
                        latitude: defaultLat,
                        longitude: defaultLng,
                        zoom: 14.5,
                        interactive: true,
                        onMapCreated: (controller) =>
                            _onMapCreated(controller, context),
                      ),
                    ),
                  ),
                  BlocBuilder<BookingBloc, BookingState>(
                    builder: (context, state) {
                      final showRadar =
                          state is FindingNearestDriver ||
                          (state is BookingSearching &&
                              state.isDirect == false) ||
                          (state is BookingOffersReceived &&
                              state.offers.isEmpty);
                      if (showRadar) {
                        return Center(
                          child: AnimatedBuilder(
                            animation: _radarCtrl,
                            builder: (ctx, _) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  ...List.generate(3, (i) {
                                    final timerSeconds =
                                        (_radarCtrl.value + i * 0.33) % 1.0;
                                    return Container(
                                      width: 60 + timerSeconds * 200,
                                      height: 60 + timerSeconds * 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withValues(
                                                alpha:
                                                    0.15 * (1 - timerSeconds),
                                              ),
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  }),
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      LucideIcons.navigation,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 600.0 : double.infinity,
                        ),
                        child: BlocBuilder<BookingBloc, BookingState>(
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
                                  child: GestureDetector(
                                    onTap: _handleCancel,
                                    child: Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.borderSide,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.arrow_left,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
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
                                          child: ChoiceChip(
                                            avatar: Icon(
                                              LucideIcons.map_pin,
                                              size: 14.0,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.primaryColor,
                                            ),
                                            label: Text(
                                              '${driver.displayName} (${DistanceFormatter.fromKilometers(driver.distanceKm)})',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppTheme.primaryColor,
                                              ),
                                            ),
                                            selected: isSelected,
                                            selectedColor:
                                                AppTheme.primaryColor,
                                            backgroundColor: AppTheme.surface,
                                            elevation: 2,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedDriver = driver;
                                                  _isViewingDriverProfile =
                                                      false;
                                                });
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if (showDriverDiscovery &&
                                    _selectedDriver != null)
                                  DriverDropdownCardWidget(
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
                      constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 600.0 : double.infinity,
                      ),
                      child: BlocBuilder<BookingBloc, BookingState>(
                        builder: (context, state) {
                          if (state is FindingNearestDriver) {
                            return FindingDriverSearchingPanelWidget(
                              message: 'Locating nearest driver',
                              rideType: widget.rideType,
                              fare: widget.fare,
                              destination: widget.destination,
                              pickupAddress: widget.pickupAddress,
                              dotAnimation: _dotCtrl,
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (_isNoDriverFound &&
                              state is BookingFailure &&
                              state.isNoDriverFound) {
                            return FindingDriverNoDriverPanelWidget(
                              rideType: widget.rideType,
                              fare: widget.fare,
                              destination: widget.destination,
                              onRetryPressed: _retryFindingDriver,
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (_driverSearchError != null &&
                              state is BookingFailure) {
                            return FindingDriverAvailabilityErrorPanelWidget(
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
                            return FindingDriverNearestPanelWidget(
                              state: state,
                              fare: widget.fare,
                              onViewFullProfilePressed: () =>
                                  _showDriverProfile(state.driver),
                              onBookDirectPressed: () =>
                                  _startDirectBooking(state.driver),
                              onSearchAllDriversPressed: _startOpenBooking,
                              onCancelRidePressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (state is BookingSearching) {
                            return FindingDriverSearchingPanelWidget(
                              message: state.isDirect
                                  ? 'Waiting for ${state.targetDriver?.displayName ?? 'driver'}'
                                  : 'Finding your driver',
                              rideType: widget.rideType,
                              fare: widget.fare,
                              destination: widget.destination,
                              pickupAddress: widget.pickupAddress,
                              dotAnimation: _dotCtrl,
                              onCancelPressed: _handleCancel,
                              isCanceling: _isLeaving,
                            );
                          } else if (state is BookingOffersReceived) {
                            if (state.offers.isEmpty) {
                              return FindingDriverSearchingPanelWidget(
                                message: state.isDirect
                                    ? 'Waiting for ${state.targetDriver?.displayName ?? 'driver'}'
                                    : 'Finding your driver',
                                rideType: widget.rideType,
                                fare: widget.fare,
                                destination: widget.destination,
                                pickupAddress: widget.pickupAddress,
                                dotAnimation: _dotCtrl,
                                onCancelPressed: _handleCancel,
                                isCanceling: _isLeaving,
                              );
                            }
                            return FindingDriverBidsPanelWidget(
                              offers: state.offers,
                              onAcceptOfferPressed: (offer) {
                                if (_isLeaving || _acceptingOfferId != null) {
                                  return;
                                }
                                setState(
                                  () => _acceptingOfferId = offer.offerId,
                                );
                                BlocProvider.of<BookingBloc>(context).add(
                                  AcceptBidOfferEvent(
                                    offerId: offer.offerId,
                                    driverId: offer.driverId,
                                    driverName: offer.driverName,
                                    vehicleType: offer.vehicleType,
                                    plateNumber: offer.plateNumber,
                                    proposedFare: offer.proposedFare,
                                    driverRating: offer.ratingStr,
                                  ),
                                );
                              },
                              onCancelPressed: _handleCancel,
                              acceptingOfferId: _acceptingOfferId,
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

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_event.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_state.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/live_map/live_map_event.dart';
import 'package:passenger_app/src/features/trip/presentation/widgets/driver_dropdown_card_widget.dart';
import 'package:passenger_app/src/features/trip/presentation/widgets/finding_driver_bids_panel_widget.dart';
import 'package:passenger_app/src/features/trip/presentation/widgets/finding_driver_nearest_panel_widget.dart';
import 'package:passenger_app/src/features/trip/presentation/widgets/finding_driver_searching_panel_widget.dart';
import 'package:passenger_app/src/shared/widgets/driver_profile_details_sheet.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:shared_ui/shared_ui.dart';

class FindingDriverScreen extends StatelessWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;

  const FindingDriverScreen({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookingBloc>(create: (_) => Modular.get<BookingBloc>()),
        BlocProvider<LiveMapBloc>(create: (_) => Modular.get<LiveMapBloc>()),
      ],
      child: FindingDriverScreenContent(
        rideType: rideType,
        fare: fare,
        destination: destination,
        distance: distance,
        duration: duration,
        pickupAddress: pickupAddress,
      ),
    );
  }
}

class FindingDriverScreenContent extends StatefulWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;

  const FindingDriverScreenContent({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
  });

  @override
  State<FindingDriverScreenContent> createState() =>
      _FindingDriverScreenContentState();
}

class _FindingDriverScreenContentState extends State<FindingDriverScreenContent>
    with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late AnimationController _dotCtrl;
  bool _initialized = false;
  DriverModel? _selectedDriver;
  List<DriverModel> _nearbyDrivers = [];

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

    final lat =
        LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final lng =
        LocationService.lastPosition?.longitude ?? widget.destination.longitude;

    BlocProvider.of<BookingBloc>(
      context,
    ).add(LocateNearestDriverEvent(pickupLat: lat, pickupLng: lng));
  }

  void _showDriverProfileSheet(DriverModel driver) {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DriverProfileDetailsSheet(
          driverId: driver.id,
          driverName: driver.name,
          vehicleType: driver.vehicleType,
          plateNumber: driver.plateNumber,
          rating: driver.rating.toStringAsFixed(1),
        ),
      ),
    );
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
      final lat =
          LocationService.lastPosition?.latitude ?? widget.destination.latitude;
      final lng =
          LocationService.lastPosition?.longitude ??
          widget.destination.longitude;

      BlocProvider.of<LiveMapBloc>(context).add(
        InitializeMapEvent(
          controller: controller,
          defaultLat: lat,
          defaultLng: lng,
        ),
      );

      BlocProvider.of<LiveMapBloc>(context).add(
        AddMapMarkerEvent(lat: lat, lng: lng, label: 'Origin', isOrigin: true),
      );
    }
  }

  void _startDirectBooking(DriverModel driver) {
    final pickupLat =
        LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final pickupLng =
        LocationService.lastPosition?.longitude ?? widget.destination.longitude;

    final distanceNum =
        double.tryParse(widget.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        1.0;
    final durationNum =
        double.tryParse(widget.duration.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        5.0;

    final tripMetadata = BidSessionTrip(
      rideType: widget.rideType,
      fare: widget.fare,
      destination: widget.destination,
      distance: widget.distance,
      duration: widget.duration,
      pickupAddress: widget.pickupAddress,
    );

    BlocProvider.of<BookingBloc>(context).add(
      StartDirectBookingEvent(
        trip: tripMetadata,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        distanceKm: distanceNum,
        durationMinutes: durationNum,
      ),
    );
  }

  void _startOpenBooking() {
    final pickupLat =
        LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final pickupLng =
        LocationService.lastPosition?.longitude ?? widget.destination.longitude;

    final distanceNum =
        double.tryParse(widget.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        1.0;
    final durationNum =
        double.tryParse(widget.duration.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        5.0;

    final tripMetadata = BidSessionTrip(
      rideType: widget.rideType,
      fare: widget.fare,
      destination: widget.destination,
      distance: widget.distance,
      duration: widget.duration,
      pickupAddress: widget.pickupAddress,
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
    BlocProvider.of<BookingBloc>(context).add(const CancelBookingEvent());
  }

  @override
  Widget build(BuildContext context) {
    final defaultLat =
        LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final defaultLng =
        LocationService.lastPosition?.longitude ?? widget.destination.longitude;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleCancel();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: BlocListener<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is NearestDriverFound) {
              setState(() {
                _nearbyDrivers = state.nearbyDrivers;
                _selectedDriver ??= state.driver;
              });
              final liveMapBloc = BlocProvider.of<LiveMapBloc>(context);
              liveMapBloc.add(
                AddMapMarkerEvent(
                  lat: state.driver.lat,
                  lng: state.driver.lng,
                  label: state.driver.name,
                ),
              );
              for (final nearby in state.nearbyDrivers) {
                if (nearby.id != state.driver.id) {
                  liveMapBloc.add(
                    AddMapMarkerEvent(
                      lat: nearby.lat,
                      lng: nearby.lng,
                      label: nearby.name,
                    ),
                  );
                }
              }
            } else if (state is BookingDriverMatched) {
              final navExtra = state.matchResult.toNavigationExtra();
              navExtra['createdRide'] = state.createdRide;
              context.pushReplacementNamed('DriverMatched', extra: navExtra);
            } else if (state is BookingFailure) {
              CustomToast.show(context, state.message, isError: true);
              context.pop();
            } else if (state is BookingCanceled) {
              context.pop();
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
                          (state is BookingSearching && state.isDirect == false) ||
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
                                          color: AppTheme.primaryColor.withValues(
                                            alpha: 0.15 * (1 - timerSeconds),
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
                                          color: AppTheme.primaryColor.withValues(
                                            alpha: 0.3,
                                          ),
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
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 600.0 : double.infinity,
                        ),
                        child: Column(
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.chevron_left,
                                        color: AppTheme.primaryColor,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Back',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_nearbyDrivers.isNotEmpty)
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
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ChoiceChip(
                                        avatar: Icon(
                                          LucideIcons.map_pin,
                                          size: 14.0,
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.primaryColor,
                                        ),
                                        label: Text(
                                          '${driver.name} (${driver.distanceKm.toStringAsFixed(1)}km)',
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
                                        selectedColor: AppTheme.primaryColor,
                                        backgroundColor: AppTheme.surface,
                                        elevation: 2,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _selectedDriver = driver;
                                            });
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            if (_selectedDriver != null)
                              DriverDropdownCardWidget(
                                driver: _selectedDriver!,
                                isNearestDriver:
                                    _nearbyDrivers.isNotEmpty &&
                                    _selectedDriver!.id == _nearbyDrivers.first.id,
                                onViewFullProfilePressed: () =>
                                    _showDriverProfileSheet(_selectedDriver!),
                                onSelectDriverPressed: () =>
                                    _startDirectBooking(_selectedDriver!),
                                onCloseDropdownPressed: () {
                                  setState(() {
                                    _selectedDriver = null;
                                  });
                                },
                              ),
                          ],
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
                            );
                          } else if (state is NearestDriverFound) {
                            return FindingDriverNearestPanelWidget(
                              state: state,
                              fare: widget.fare,
                              onViewFullProfilePressed: () =>
                                  _showDriverProfileSheet(state.driver),
                              onBookDirectPressed: () =>
                                  _startDirectBooking(state.driver),
                              onSearchAllDriversPressed: _startOpenBooking,
                              onCancelRidePressed: _handleCancel,
                            );
                          } else if (state is BookingSearching) {
                            return FindingDriverSearchingPanelWidget(
                              message: state.isDirect
                                  ? 'Waiting for ${state.targetDriver?.name ?? 'driver'}'
                                  : 'Finding your driver',
                              rideType: widget.rideType,
                              fare: widget.fare,
                              destination: widget.destination,
                              pickupAddress: widget.pickupAddress,
                              dotAnimation: _dotCtrl,
                              onCancelPressed: _handleCancel,
                            );
                          } else if (state is BookingOffersReceived) {
                            if (state.offers.isEmpty) {
                              return FindingDriverSearchingPanelWidget(
                                message: state.isDirect
                                    ? 'Waiting for ${state.targetDriver?.name ?? 'driver'}'
                                    : 'Finding your driver',
                                rideType: widget.rideType,
                                fare: widget.fare,
                                destination: widget.destination,
                                pickupAddress: widget.pickupAddress,
                                dotAnimation: _dotCtrl,
                                onCancelPressed: _handleCancel,
                              );
                            }
                            return FindingDriverBidsPanelWidget(
                              offers: state.offers,
                              fallbackFare: widget.fare,
                              onAcceptOfferPressed: (offer) {
                                BlocProvider.of<BookingBloc>(context).add(
                                  AcceptBidOfferEvent(
                                    offerId: offer.offerId,
                                    driverId: offer.driverId,
                                    driverName: offer.driverName,
                                    vehicleType: offer.vehicleType,
                                    plateNumber: offer.plateNumber,
                                    proposedFare: offer.proposedFare,
                                  ),
                                );
                              },
                              onCancelPressed: _handleCancel,
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

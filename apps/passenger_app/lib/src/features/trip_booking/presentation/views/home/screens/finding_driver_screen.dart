import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/services/bid_session_service.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/booking/booking_event.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/booking/booking_state.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/live_map/live_map_event.dart';
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
        BlocProvider<BookingBloc>(create: (_) => getIt<BookingBloc>()),
        BlocProvider<LiveMapBloc>(create: (_) => getIt<LiveMapBloc>()),
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
              BlocProvider.of<LiveMapBloc>(context).add(
                AddMapMarkerEvent(
                  lat: state.driver.lat,
                  lng: state.driver.lng,
                  label: state.driver.name,
                ),
              );
            } else if (state is BookingDriverMatched) {
              final navExtra = state.matchResult.toNavigationExtra();
              navExtra['createdRide'] = state.createdRide;
              context.pushReplacementNamed('DriverMatched', extra: navExtra);
            } else if (state is BookingCanceled) {
              context.pop();
            }
          },
          child: Stack(
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
                      (state is BookingOffersReceived && state.offers.isEmpty);
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
                child: Padding(
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
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: BlocBuilder<BookingBloc, BookingState>(
                  builder: (context, state) {
                    if (state is FindingNearestDriver) {
                      return _buildSearchingPanel(
                        message: 'Locating nearest driver',
                      );
                    } else if (state is NearestDriverFound) {
                      return _buildNearestDriverPanel(state);
                    } else if (state is BookingSearching) {
                      return _buildSearchingPanel(
                        message: state.isDirect
                            ? 'Waiting for ${state.targetDriver?.name ?? 'driver'}'
                            : 'Finding your driver',
                      );
                    } else if (state is BookingOffersReceived) {
                      if (state.offers.isEmpty) {
                        return _buildSearchingPanel(
                          message: state.isDirect
                              ? 'Waiting for ${state.targetDriver?.name ?? 'driver'}'
                              : 'Finding your driver',
                        );
                      }
                      return _buildBidsPanel(state.offers);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingPanel({String message = 'Finding your driver'}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _dotCtrl,
            builder: (ctx, _) {
              final dots = '.' * (1 + (_dotCtrl.value * 3).floor());
              return Text(
                '$message$dots',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.pickupAddress != null
                ? 'Request sent. The driver is reviewing your trip details.'
                : 'Looking for ${widget.rideType} drivers nearby...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSide),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.map_pin,
                      size: 16,
                      color: AppTheme.tertiaryColor,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 160,
                      child: Text(
                        widget.destination.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${widget.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cancel.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Text(
                'Cancel Search',
                style: TextStyle(
                  color: AppTheme.cancel,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearestDriverPanel(NearestDriverFound state) {
    final driver = state.driver;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${driver.vehicleType} • ${driver.plateNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${widget.fare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${driver.distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.tertiaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppTheme.borderSide),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricCard(
                icon: LucideIcons.star,
                value: driver.rating.toStringAsFixed(1),
                label: 'Rating',
                iconColor: Colors.amber,
              ),
              Container(width: 1, height: 40, color: AppTheme.borderSide),
              _buildMetricCard(
                icon: LucideIcons.bike,
                value: '${state.totalTrips}',
                label: 'Total Trips',
                iconColor: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Passenger Reviews',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          if (state.isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          else if (state.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No reviews yet for this driver.',
                style: TextStyle(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.reviews.length,
                itemBuilder: (context, index) {
                  final review = state.reviews[index];
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neutralColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSide),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review['passengerName'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              review['date'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (starIndex) {
                              final ratingValue = (review['rating'] as num?)?.toDouble() ?? 5.0;
                              if (ratingValue >= starIndex + 1) {
                                return const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 13,
                                );
                              } else if (ratingValue >= starIndex + 0.5) {
                                return const Icon(
                                  Icons.star_half_rounded,
                                  color: Colors.amber,
                                  size: 13,
                                );
                              } else {
                                return Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                  size: 13,
                                );
                              }
                            }),
                            const SizedBox(width: 6),
                            Text(
                              ((review['rating'] as num?)?.toDouble() ?? 5.0).toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            review['comment'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: AppTheme.primaryColor.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _startDirectBooking(driver),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(32),
              ),
              alignment: Alignment.center,
              child: Text(
                'Book ${driver.name} Directly',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _startOpenBooking,
                  child: Text(
                    'Search All Drivers',
                    style: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _handleCancel,
                  child: const Text(
                    'Cancel Ride',
                    style: TextStyle(
                      color: AppTheme.cancel,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBidsPanel(List<dynamic> offers) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Select Driver Offer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Drivers nearby have placed these bids for your trip',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                if (offer is! Map<String, dynamic>) {
                  return const SizedBox.shrink();
                }

                final offerId =
                    offer['offer_id'] as String? ??
                    offer['id'] as String? ??
                    '';
                final driverName = offer['driver_name'] as String? ?? 'Driver';
                final vehicle = offer['vehicle_type'] as String? ?? 'Bao Bao';
                final plate = offer['plate_number'] as String? ?? '';
                final ratingStr = offer['driver_rating']?.toString() ?? '5.0';
                final proposedFare =
                    (offer['proposed_fare'] as num?)?.toDouble() ?? widget.fare;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSide),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$vehicle • $plate',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ratingStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${proposedFare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              BlocProvider.of<BookingBloc>(context).add(
                                AcceptBidOfferEvent(
                                  offerId: offerId,
                                  driverName: driverName,
                                  vehicleType: vehicle,
                                  plateNumber: plate,
                                  proposedFare: proposedFare,
                                ),
                              );
                            },
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cancel.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Text(
                'Cancel Ride Request',
                style: TextStyle(
                  color: AppTheme.cancel,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

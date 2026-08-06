import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/entities/booking_draft.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/features/trip/view/widgets/booking_auth_bottom_sheet_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_options_panel_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class RideSelectionPage extends StatefulWidget {
  final PlaceModel destination;
  final String distance;
  final String duration;
  final double distanceKm;
  final String? pickupAddress;

  const RideSelectionPage({
    super.key,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.distanceKm,
    this.pickupAddress,
  });

  @override
  State<RideSelectionPage> createState() => _RideSelectionPageState();
}

class _RideSelectionPageState extends State<RideSelectionPage> {
  int _selectedIdx = 0;
  late List<RideOptionData> _options;
  final TextEditingController _customFareController = TextEditingController();
  double? _minimumFare;
  String? _fareError;
  AppMapController? _mapController;
  Widget? _cachedMapView;

  @override
  void initState() {
    super.initState();
    initializeRideOptionsData();
    unawaited(fetchServerFareQuotes());
  }

  void initializeRideOptionsData() {
    _options = const [];
  }

  Future<void> fetchServerFareQuotes() async {
    final position = LocationService.lastPosition;
    if (position == null) {
      if (mounted) {
        setState(() => _fareError = 'Your pickup location is unavailable.');
      }
      return;
    }
    final distanceKm = widget.distanceKm;
    final durationMins = double.tryParse(
      widget.duration.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (durationMins == null) {
      if (mounted) {
        setState(() => _fareError = 'Route duration is unavailable.');
      }
      return;
    }

    try {
      final datasource = Modular.get<BiddingRemoteDataSource>();
      final pricingConfig = await datasource.fetchPricingConfig();
      final res = await datasource.fetchFareEstimate(
        distanceKm: distanceKm,
        durationMinutes: durationMins,
        rideType: 'solo',
        originLatitude: position.latitude,
        originLongitude: position.longitude,
        destinationLatitude: widget.destination.latitude,
        destinationLongitude: widget.destination.longitude,
      );
      final totalFare =
          (res['total_fare'] as num?)?.toDouble() ??
          ((res['fare_centavos'] as num?)?.toDouble() ?? 0) / 100;
      if (totalFare > 0 && mounted) {
        setState(() {
          _minimumFare = totalFare;
          _customFareController.text = totalFare.toStringAsFixed(2);
          _options = [
            RideOptionData(
              name: pricingConfig.serviceName,
              subtitle: 'Private ride with a server-calculated minimum fare',
              icon: LucideIcons.bike,
              fare: totalFare,
              eta: 'Server calculated',
              badge: null,
            ),
          ];
          _fareError = null;
        });
      } else if (mounted) {
        setState(() => _fareError = 'The server did not return a valid fare.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _fareError = 'Unable to calculate the fare right now.');
      }
    }
  }

  void _onCustomFareChanged(String value) {
    final minimumFare = _minimumFare;
    if (minimumFare == null) return;
    final enteredFare = double.tryParse(value);
    setState(() {
      _fareError = enteredFare == null
          ? 'Enter a valid custom offer.'
          : enteredFare < minimumFare
          ? 'Custom offer cannot be lower than calculated minimum fare.'
          : null;
    });
  }

  double? get _selectedFare => double.tryParse(_customFareController.text);

  Future<void> _handleBookPressed() async {
    final fare = _selectedFare;
    final minimumFare = _minimumFare;
    if (fare == null || minimumFare == null || fare < minimumFare) {
      return;
    }

    final bookingBloc = BlocProvider.of<BookingBloc>(context);
    if (bookingBloc.hasActiveBooking) {
      CustomToast.show(
        context,
        'A driver search is already in progress.',
        isError: true,
      );
      return;
    }

    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState is! AuthenticatedSession) {
      BlocProvider.of<BookingDraftCubit>(context).save(
        BookingDraft(
          destination: widget.destination,
          pickupAddress: widget.pickupAddress,
        ),
      );
      final action = await showModalBottomSheet<BookingAuthAction>(
        context: context,
        backgroundColor: AppTheme.surface,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        barrierColor: Colors.black54,
        useSafeArea: true,
        builder: (_) => const BookingAuthBottomSheetWidget(),
      );
      if (!mounted || action == null) return;
      final authRoute = switch (action) {
        BookingAuthAction.signIn => AuthRoutes.signin,
        BookingAuthAction.signUp => AuthRoutes.signup,
      };
      unawaited(context.pushNamed(authRoute));
      return;
    }

    BlocProvider.of<BookingDraftCubit>(context).clear();
    unawaited(
      context.pushNamed(
        TripRoutes.findingDriver,
        extra: {
          'rideType': 'solo',
          'fare': fare,
          'destination': widget.destination,
          'distance': widget.distance,
          'duration': widget.duration,
          'pickupAddress': widget.pickupAddress,
        },
      ),
    );
  }

  @override
  void dispose() {
    _customFareController.dispose();
    super.dispose();
  }

  Future<void> _drawRoute() async {
    if (_mapController == null) return;

    final position = LocationService.lastPosition;
    if (position == null) return;
    final pickupLat = position.latitude;
    final pickupLng = position.longitude;
    final destLat = widget.destination.latitude;
    final destLng = widget.destination.longitude;

    try {
      final route = await MapProvider.getRoute(
        pickupLat,
        pickupLng,
        destLat,
        destLng,
      );
      if (route != null && mounted) {
        await MapProvider.addMarker(
          _mapController!,
          pickupLat,
          pickupLng,
          isOrigin: true,
          label: 'Current location\nYou are here',
        );
        await MapProvider.addMarker(
          _mapController!,
          destLat,
          destLng,
          isOrigin: false,
          label: 'Your destination\n${widget.destination.name}',
        );
        await MapProvider.addPolyline(
          _mapController!,
          route.polylinePoints,
          color: AppTheme.primaryColor,
          width: 5.0,
        );
        final routePoints = route.polylinePoints
            .where((point) => point.length >= 2)
            .map((point) => LatLng(point[1], point[0]));
        await MapProvider.fitBounds(
          _mapController!,
          [
            LatLng(pickupLat, pickupLng),
            LatLng(destLat, destLng),
            ...routePoints,
          ],
          padding: 80.0,
          maxZoom: 14.5,
        );
      }
    } catch (error) {
      debugPrint('Error drawing route preview: $error');
    }
  }

  Widget _buildMapView(double latitude, double longitude) {
    return _cachedMapView ??= MapProvider.buildMapView(
      latitude: latitude,
      longitude: longitude,
      zoom: 13.5,
      interactive: true,
      onMapCreated: (controller) {
        _mapController = controller;
        unawaited(_drawRoute());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = LocationService.lastPosition;
    if (position == null) {
      return const Scaffold(
        body: Center(child: Text('Your location is unavailable.')),
      );
    }
    final defaultLat = position.latitude;
    final defaultLng = position.longitude;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppTheme.neutralColor,
              child: SizedBox.expand(
                child: _buildMapView(defaultLat, defaultLng),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderSide),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
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
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 600.0;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 600.0 : double.infinity,
                  ),
                  child: RideOptionsPanelWidget(
                    options: _options,
                    selectedIndex: _selectedIdx,
                    onOptionSelected: (idx) {
                      setState(() {
                        _selectedIdx = idx;
                      });
                    },
                    customFareController: _customFareController,
                    minimumFare: _minimumFare,
                    customFareError: _fareError,
                    onCustomFareChanged: _onCustomFareChanged,
                    onBookPressed: () => unawaited(_handleBookPressed()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

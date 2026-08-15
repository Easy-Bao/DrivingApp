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
  final double? pickupLatitude;
  final double? pickupLongitude;

  const RideSelectionPage({
    super.key,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.distanceKm,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
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
  String? _customFareError;
  bool _isLoadingFare = true;
  AppMapController? _mapController;
  Widget? _cachedMapView;
  RouteModel? _route;
  Future<RouteModel?>? _routeRequest;

  ({double lat, double lng})? get _pickupCoordinate {
    final latitude = widget.pickupLatitude;
    final longitude = widget.pickupLongitude;
    if (latitude != null && longitude != null) {
      return (lat: latitude, lng: longitude);
    }
    final position = LocationService.lastPosition;
    if (position == null) return null;
    return (lat: position.latitude, lng: position.longitude);
  }

  @override
  void initState() {
    super.initState();
    initializeRideOptionsData();
    unawaited(_initializeTripDetails());
  }

  void initializeRideOptionsData() {
    _options = const [];
  }

  Future<void> _initializeTripDetails() async {
    if (mounted) {
      setState(() {
        _isLoadingFare = true;
        _fareError = null;
        _customFareError = null;
      });
    }

    try {
      final route = await _loadRoute();
      if (!mounted) return;

      final distanceKm =
          _positiveValue(route?.distanceKm) ??
          _positiveValue(widget.distanceKm);
      final durationMinutes = route != null && route.durationSeconds > 0
          ? route.durationSeconds / 60.0
          : _parseDurationMinutes(widget.duration);
      if (distanceKm == null || durationMinutes == null) {
        setState(() {
          _isLoadingFare = false;
          _fareError = 'We couldn’t determine the route details for this trip.';
          _options = const [];
          _minimumFare = null;
          _customFareController.clear();
        });
        return;
      }

      await _fetchServerFareQuotes(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFare = false;
          _fareError =
              'We couldn’t load the fare for this route. Please try again.';
          _options = const [];
          _minimumFare = null;
          _customFareController.clear();
        });
      }
    }
  }

  Future<RouteModel?> _loadRoute() async {
    final cachedRoute = _route;
    if (cachedRoute != null) return cachedRoute;

    final ongoingRequest = _routeRequest;
    if (ongoingRequest != null) return ongoingRequest;

    final pickup = _pickupCoordinate;
    if (pickup == null) return null;

    final request = MapProvider.getRoute(
      pickup.lat,
      pickup.lng,
      widget.destination.latitude,
      widget.destination.longitude,
      preference: RoutePreference.shortest,
    );
    _routeRequest = request;
    try {
      final route = await request;
      if (route != null && mounted) {
        setState(() => _route = route);
      }
      return route;
    } finally {
      if (identical(_routeRequest, request)) {
        _routeRequest = null;
      }
    }
  }

  Future<void> _fetchServerFareQuotes({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    if (mounted) {
      setState(() {
        _isLoadingFare = true;
        _fareError = null;
        _customFareError = null;
      });
    }

    try {
      final pickup = _pickupCoordinate;
      if (pickup == null) {
        throw StateError('Pickup location is unavailable.');
      }
      final datasource = Modular.get<BiddingRemoteDataSource>();
      final pricingConfig = await datasource.fetchPricingConfig();
      final res = await datasource.fetchFareEstimate(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        rideType: 'solo',
        originLatitude: pickup.lat,
        originLongitude: pickup.lng,
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
              subtitle: 'Private ride with a calculated minimum fare',
              icon: LucideIcons.bike,
              fare: totalFare,
              eta: 'Estimated for this route',
              badge: null,
            ),
          ];
          _fareError = null;
          _customFareError = null;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingFare = false;
          _fareError = 'We couldn’t calculate a fare for this route.';
          _options = const [];
          _minimumFare = null;
          _customFareController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFare = false;
          _fareError =
              'We couldn’t calculate a fare for this route. Please try again.';
          _options = const [];
          _minimumFare = null;
          _customFareController.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFare = false);
      }
    }
  }

  void _retryFareCalculation() {
    unawaited(_initializeTripDetails());
  }

  static double? _positiveValue(double? value) {
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  static double? _parseDurationMinutes(String rawDuration) {
    final value = rawDuration.trim().toLowerCase();
    if (value.isEmpty) return null;

    final hours = double.tryParse(
      RegExp(r'(\d+(?:\.\d+)?)\s*h').firstMatch(value)?.group(1) ?? '',
    );
    final minutes = double.tryParse(
      RegExp(r'(\d+(?:\.\d+)?)\s*m').firstMatch(value)?.group(1) ?? '',
    );
    if (hours != null || minutes != null) {
      final totalMinutes = (hours ?? 0) * 60 + (minutes ?? 0);
      return _positiveValue(totalMinutes);
    }

    final numericValue = double.tryParse(
      value.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    return _positiveValue(numericValue);
  }

  void _onCustomFareChanged(String value) {
    final minimumFare = _minimumFare;
    if (minimumFare == null) return;
    final enteredFare = double.tryParse(value);
    setState(() {
      _customFareError = enteredFare == null
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
          'pickupLat': _pickupCoordinate?.lat,
          'pickupLng': _pickupCoordinate?.lng,
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

    final pickup = _pickupCoordinate;
    if (pickup == null) return;
    final pickupLat = pickup.lat;
    final pickupLng = pickup.lng;
    final destLat = widget.destination.latitude;
    final destLng = widget.destination.longitude;

    try {
      final route = await _loadRoute();
      if (route != null && route.hasGeometry && mounted) {
        final routePoints = route.validPolylinePoints;
        await MapProvider.addMarker(
          _mapController!,
          pickupLat,
          pickupLng,
          isOrigin: true,
          label: 'Pickup point\nDriver will meet you here',
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
          routePoints,
          color: AppTheme.primaryColor,
          width: 5.0,
        );
        await MapProvider.fitBounds(
          _mapController!,
          [
            LatLng(pickupLat, pickupLng),
            LatLng(destLat, destLng),
            ...routePoints.map((point) => LatLng(point[1], point[0])),
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
    final pickup = _pickupCoordinate;
    if (pickup == null) {
      return const Scaffold(
        body: Center(child: Text('Your location is unavailable.')),
      );
    }
    final defaultLat = pickup.lat;
    final defaultLng = pickup.lng;

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
                    customFareError: _customFareError,
                    isLoadingFare: _isLoadingFare,
                    fareError: _fareError,
                    onRetryFare: _retryFareCalculation,
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

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
import 'package:passenger_app/src/features/trip/domain/entities/booking_draft.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_fare_repository.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/features/trip/view/widgets/booking_auth_bottom_sheet_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_options_panel_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_tip_selector_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class RideSelectionPage extends StatefulWidget {
  final PlaceModel destination;
  final String? distance;
  final String? duration;
  final double? distanceKm;
  final String rideType;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final int initialTipAmount;
  final String initialNotes;
  final IFareRepository fareRepository;

  const RideSelectionPage({
    super.key,
    required this.destination,
    this.distance,
    this.duration,
    this.distanceKm,
    this.rideType = 'solo',
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.initialTipAmount = 0,
    this.initialNotes = '',
    required this.fareRepository,
  });

  @override
  State<RideSelectionPage> createState() => _RideSelectionPageState();
}

class _RideSelectionPageState extends State<RideSelectionPage> {
  late int _selectedTipAmount;
  final TextEditingController _customFareController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  FareResult? _fareResult;
  String? _fareError;
  String? _customFareError;
  bool _isLoadingFare = true;
  AppMapController? _mapController;
  Widget? _cachedMapView;
  RouteModel? _route;
  Future<RouteModel?>? _routeRequest;
  Future<void>? _fareQuoteRequest;
  bool _isResolvingPickup = true;
  ({double lat, double lng})? _resolvedPickup;

  ({double lat, double lng})? get _pickupCoordinate {
    final latitude = widget.pickupLatitude;
    final longitude = widget.pickupLongitude;
    if (latitude != null && longitude != null) {
      return (lat: latitude, lng: longitude);
    }
    final resolvedPickup = _resolvedPickup;
    if (resolvedPickup != null) return resolvedPickup;
    final position = LocationService.lastPosition;
    if (position == null) return null;
    return (lat: position.latitude, lng: position.longitude);
  }

  String get _pickupLabel {
    final address = widget.pickupAddress?.trim();
    return address == null || address.isEmpty ? 'Current location' : address;
  }

  String get _distanceLabel {
    final route = _route;
    if (route != null && route.distanceKm > 0) {
      return DistanceFormatter.fromKilometers(route.distanceKm);
    }
    return widget.distance ?? '';
  }

  String get _durationLabel {
    final route = _route;
    if (route != null && route.durationSeconds > 0) {
      return '${(route.durationSeconds / 60.0).ceil()} min';
    }
    return widget.duration ?? '';
  }

  double? get _effectiveDistanceKm =>
      _positiveValue(_route?.distanceKm) ?? _positiveValue(widget.distanceKm);

  double? get _effectiveDurationMinutes {
    final route = _route;
    if (route != null && route.durationSeconds > 0) {
      return route.durationSeconds / 60.0;
    }
    final duration = widget.duration;
    return duration == null ? null : _parseDurationMinutes(duration);
  }

  double? get _minimumFare => _fareResult?.totalFare;

  double get _baseFare {
    return double.tryParse(_customFareController.text) ?? _minimumFare ?? 0;
  }

  double get _totalFare => _baseFare + _selectedTipAmount;

  @override
  void initState() {
    super.initState();
    _selectedTipAmount =
        RideTipSelectorWidget.tipOptions.contains(widget.initialTipAmount)
        ? widget.initialTipAmount
        : 0;
    _notesController.text = widget.initialNotes;
    if (_pickupCoordinate != null) {
      _isResolvingPickup = false;
      unawaited(_initializeTripDetails());
    } else {
      unawaited(_resolvePickupLocation());
    }
  }

  Future<void> _resolvePickupLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position != null) {
        setState(() {
          _resolvedPickup = (lat: position.latitude, lng: position.longitude);
          _isResolvingPickup = false;
        });
        await _initializeTripDetails();
        return;
      }
    } catch (_) {
      // The fare panel will render the location-unavailable recovery state.
    }
    if (!mounted) return;
    setState(() => _isResolvingPickup = false);
    await _initializeTripDetails();
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
      await _loadRoute();
      if (!mounted) return;
      unawaited(_drawRoute());

      final distanceKm = _effectiveDistanceKm;
      final durationMinutes = _effectiveDurationMinutes;
      if (distanceKm == null || durationMinutes == null) {
        setState(() {
          _isLoadingFare = false;
          _fareError = 'We couldn’t determine the route details for this trip.';
          _fareResult = null;
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
          _fareResult = null;
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
    final activeRequest = _fareQuoteRequest;
    if (activeRequest != null) {
      await activeRequest;
      return;
    }

    final request = _requestServerFareQuote(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
    _fareQuoteRequest = request;

    try {
      await request;
    } finally {
      if (identical(_fareQuoteRequest, request)) {
        _fareQuoteRequest = null;
      }
    }
  }

  Future<void> _requestServerFareQuote({
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
      FareResult? fareResult;
      (await widget.fareRepository.estimateFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        originLatitude: pickup.lat,
        originLongitude: pickup.lng,
        destinationLatitude: widget.destination.latitude,
        destinationLongitude: widget.destination.longitude,
      )).fold((failure) => throw failure, (value) => fareResult = value);
      if (fareResult != null && mounted) {
        setState(() {
          _fareResult = fareResult;
          _customFareController.text = fareResult!.totalFare.toStringAsFixed(2);
          _fareError = null;
          _customFareError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFare = false;
          _fareError =
              'We couldn’t calculate a fare for this route. Please try again.';
          _fareResult = null;
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

  void _onTipSelected(int amount) {
    if (!mounted) return;
    setState(() => _selectedTipAmount = amount);
  }

  void _onNotesChanged(String _) {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleBookPressed() async {
    final fare = _selectedFare;
    final minimumFare = _minimumFare;
    if (fare == null || minimumFare == null || fare < minimumFare) {
      return;
    }
    final totalFare = fare + _selectedTipAmount;

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
          tipAmount: _selectedTipAmount,
          notes: _notesController.text.trim(),
        ),
      );
      final action = await showModalBottomSheet<BookingAuthAction>(
        context: context,
        backgroundColor: AppTheme.surface,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        barrierColor: AppTheme.primaryColor.withValues(alpha: 0.54),
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
          'rideType': widget.rideType,
          'fare': totalFare,
          'destination': widget.destination,
          'distance': _distanceLabel,
          'duration': _durationLabel,
          'pickupAddress': widget.pickupAddress,
          'pickupLat': _pickupCoordinate?.lat,
          'pickupLng': _pickupCoordinate?.lng,
          'passengerNote': _notesController.text.trim(),
        },
      ),
    );
  }

  @override
  void dispose() {
    _customFareController.dispose();
    _notesController.dispose();
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
          color: TripMapMarkerStyle.ownLocation,
        );
        await MapProvider.addMarker(
          _mapController!,
          destLat,
          destLng,
          isOrigin: false,
          color: TripMapMarkerStyle.tripLocation,
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
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: _isResolvingPickup
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Getting your current location…'),
                  ],
                )
              : const Text('Your location is unavailable.'),
        ),
      );
    }
    final defaultLat = pickup.lat;
    final defaultLng = pickup.lng;
    final passengerName = switch (context.watch<SessionBloc>().state) {
      AuthenticatedSession(:final passengerName) => passengerName,
      _ => '',
    };

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
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
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
                    maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                  ),
                  child: RideOptionsPanelWidget(
                    passengerName: passengerName,
                    pickupLabel: _pickupLabel,
                    destinationName: widget.destination.name,
                    destinationAddress: widget.destination.fullAddress,
                    fareResult: _fareResult,
                    customFareController: _customFareController,
                    customFareError: _customFareError,
                    isLoadingFare: _isLoadingFare,
                    fareError: _fareError,
                    onRetryFare: _retryFareCalculation,
                    onCustomFareChanged: _onCustomFareChanged,
                    notesController: _notesController,
                    onNotesChanged: _onNotesChanged,
                    selectedTipAmount: _selectedTipAmount,
                    onTipSelected: _onTipSelected,
                    totalFare: _totalFare,
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

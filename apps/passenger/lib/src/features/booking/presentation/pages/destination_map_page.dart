import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart' hide Route;
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';

class const DestinationMapPage({
  super.key,
  required this.placeName,
  required this.placeSubtitle,
  required this.destinationLat,
  required this.destinationLng,
}) extends StatefulWidget {
  final String placeName;
  final String placeSubtitle;
  final double destinationLat;
  final double destinationLng;

  @override
  State<DestinationMapPage> createState() => _DestinationMapPageState();
}

class _DestinationMapPageState() extends State<DestinationMapPage> {
  AppMapController? _mapController;
  Widget? _cachedMapView;
  String _fullAddress = '';
  bool _isLoading = true;
  String? _loadError;
  bool _routeDataLoaded = false;
  Future<void>? _routeDataRequest;
  Future<void>? _routeRenderRequest;
  ({double lat, double lng})? _originCoordinate;
  Route? _route;

  @override
  void initState() {
    super.initState();
    _ensureRouteDataLoaded();
  }

  void _retryLoadRouteData() {
    if (_routeDataRequest != null) return;
    setState(() {
      _routeDataLoaded = false;
      _isLoading = true;
      _loadError = null;
    });
    _ensureRouteDataLoaded();
  }

  void _ensureRouteDataLoaded() {
    if (_routeDataLoaded) {
      unawaited(_ensureRouteDataRendered());
      return;
    }
    if (_routeDataRequest != null) return;

    final request = _loadRouteData();
    _routeDataRequest = request;
    unawaited(
      request.whenComplete(() {
        if (identical(_routeDataRequest, request)) {
          _routeDataRequest = null;
        }
      }),
    );
  }

  Future<void> _loadRouteData() async {
    try {
      final position = await LocationService.getCurrentPosition();
      final originPosition = position ?? LocationService.lastPosition;
      final origin = originPosition == null
          ? null
          : (lat: originPosition.latitude, lng: originPosition.longitude);

      _originCoordinate = origin;
      final placeRequest = MapProvider.getPlaceFromCoordinates(
        widget.destinationLat,
        widget.destinationLng,
      );
      if (!mounted) return;
      final isAuthenticated =
          BlocProvider.of<SessionBloc>(context).state is AuthenticatedSession;
      final routeRequest = origin == null || !isAuthenticated
          ? Future<Route?>.value(null)
          : MapProvider.getRoute(
              origin.lat,
              origin.lng,
              widget.destinationLat,
              widget.destinationLng,
            );
      final place = await placeRequest;
      _route = await routeRequest;

      if (!mounted) return;
      _routeDataLoaded = true;
      setState(() {
        _fullAddress = place?.fullAddress ?? widget.placeSubtitle;
        _isLoading = false;
        _loadError = null;
      });
      await _ensureRouteDataRendered();
    } catch (error) {
      if (!mounted) return;
      _routeDataLoaded = true;
      setState(() {
        _fullAddress = widget.placeSubtitle;
        _isLoading = false;
        _loadError = 'Unable to load route details. Try again.';
      });
      debugPrint('Unable to load destination route: $error');
    }
  }

  Future<void> _ensureRouteDataRendered() {
    final ongoingRequest = _routeRenderRequest;
    if (ongoingRequest != null) return ongoingRequest;

    final request = _renderRouteData();
    _routeRenderRequest = request;
    unawaited(
      request.whenComplete(() {
        if (identical(_routeRenderRequest, request)) {
          _routeRenderRequest = null;
        }
      }),
    );
    return request;
  }

  Future<void> _renderRouteData() async {
    if (!mounted) return;
    final controller = _mapController;
    final origin = _originCoordinate;
    if (controller == null || origin == null) return;
    final routeColor = context.colorScheme.onSurface;

    try {
      await MapProvider.addMarker(
        controller,
        origin.lat,
        origin.lng,
        isOrigin: true,
        color: TripMapMarkerStyle.ownLocation,
      );
      await MapProvider.addMarker(
        controller,
        widget.destinationLat,
        widget.destinationLng,
        color: TripMapMarkerStyle.tripLocation,
      );
      await MapProvider.fitBounds(controller, [
        LatLng(origin.lat, origin.lng),
        LatLng(widget.destinationLat, widget.destinationLng),
      ]);

      final route = _route;
      if (route == null || !route.hasGeometry) return;
      await MapProvider.addPolylineBuffer(
        controller,
        route.coordinateBuffer,
        color: routeColor,
        width: 5.0,
      );
    } catch (error) {
      debugPrint('Unable to render destination route: $error');
    }
  }

  Widget _buildMapView() {
    return _cachedMapView ??= MapProvider.buildMapView(
      latitude: widget.destinationLat,
      longitude: widget.destinationLng,
      zoom: 13.0,
      onMapCreated: (controller) {
        _mapController = controller;
        _ensureRouteDataLoaded();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final origin = _originCoordinate;
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapView()),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            child: AppMapBackButton(onPressed: () => context.pop()),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomSheetContainer(
              showShadow: true,
              backgroundColor: context.colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(
                AppLayout.pagePaddingWide,
                AppSpacing.md,
                AppLayout.pagePaddingWide,
                AppSpacing.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(
                          LucideIcons.map_pin,
                          color: context.colorScheme.onSurface,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.placeName,
                              style: context.textStyles.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading ? 'Fetching address…' : _fullAddress,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_loadError case final loadError?) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppErrorBanner(
                      message: loadError,
                      onRetry: _retryLoadRouteData,
                      onDismiss: () => setState(() => _loadError = null),
                    ),
                  ],
                  const SizedBox(height: 20),
                  CompactRouteTimeline(
                    pickup: 'Current Location',
                    dropoff: widget.placeName,
                    pickupLabel: 'From',
                    dropoffLabel: 'Destination',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: AppSize.controlHeight,
                    child: FilledButton(
                      onPressed: () {
                        final resolvedAddress = _fullAddress.trim().isNotEmpty
                            ? _fullAddress.trim()
                            : widget.placeSubtitle;
                        final place = Place(
                          id: 'destination_place_${widget.placeName.replaceAll(' ', '_')}',
                          name: widget.placeName,
                          fullAddress: resolvedAddress,
                          latitude: widget.destinationLat,
                          longitude: widget.destinationLng,
                        );
                        unawaited(
                          context.pushNamed(
                            BookingRoutes.rideSelection,
                            extra: place,
                            queryParameters: {
                              if (origin != null) ...{
                                'pickupLat': origin.lat.toString(),
                                'pickupLng': origin.lng.toString(),
                              },
                            },
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Book ride',
                        style: context.textStyles.titleSmall?.copyWith(
                          color: context.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

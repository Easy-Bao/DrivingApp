import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/map_pin_address_formatter.dart';
import 'package:passenger/src/features/booking/presentation/widgets/map_selection_marker_widget.dart';

enum MapPinFlow { pickup, savedPlace }

class const MapPinPage({super.key, this.flow = MapPinFlow.pickup})
    extends StatefulWidget {
  final MapPinFlow flow;

  @override
  State<MapPinPage> createState() => _MapPinPageState();
}

class _MapPinPageState()
    extends State<MapPinPage>
    with SingleTickerProviderStateMixin {
  AppMapController? _mapController;
  String _address = 'Move the map to select a location';
  String _subAddress = '';
  bool _isGeocoding = false;
  bool _hasUserPannedMap = false;
  bool _isProgrammaticCameraMove = false;
  int _geocodeRequestId = 0;
  late final AnimationController _pinAnimationController;
  double? _centerLat = LocationService.lastPosition?.latitude;
  double? _centerLng = LocationService.lastPosition?.longitude;
  Widget? _cachedMapView;

  @override
  void initState() {
    super.initState();
    _pinAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 220),
    );
    if (_centerLat != null && _centerLng != null) {
      unawaited(_reverseGeocode(_centerLat!, _centerLng!));
    }
    unawaited(_initLocation());
  }

  @override
  void dispose() {
    _pinAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (_centerLat == null || _centerLng == null) {
      final hasLocationAccess =
          await LocationService.getAccessState() == LocationAccessState.ready;
      if (!hasLocationAccess) {
        if (mounted) context.pop();
        return;
      }
    }

    final pos = _centerLat != null && _centerLng != null
        ? null
        : await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      if (!_hasUserPannedMap) {
        setState(() {
          _centerLat = pos.latitude;
          _centerLng = pos.longitude;
        });
        if (_mapController != null) {
          _isProgrammaticCameraMove = true;
          try {
            await MapProvider.moveCamera(
              _mapController!,
              pos.latitude,
              pos.longitude,
              zoom: 15.0,
            );
          } finally {
            _isProgrammaticCameraMove = false;
          }
        }
      }
      if (!_hasUserPannedMap) {
        unawaited(_reverseGeocode(pos.latitude, pos.longitude));
      }
    } else if (mounted && _address == 'Move the map to select a location') {
      if (_centerLat != null && _centerLng != null) {
        unawaited(_reverseGeocode(_centerLat!, _centerLng!));
      }
    }
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (_centerLat != null && _centerLng != null) {
      _isProgrammaticCameraMove = true;
      unawaited(
        MapProvider.moveCamera(
          controller,
          _centerLat!,
          _centerLng!,
          zoom: 15.0,
        ).whenComplete(() => _isProgrammaticCameraMove = false),
      );
      if (!_hasUserPannedMap) {
        unawaited(_reverseGeocode(_centerLat!, _centerLng!));
      }
    }
  }

  void _onCameraChanged(AppMapController controller) {
    if (_isProgrammaticCameraMove) return;
    _hasUserPannedMap = true;
    unawaited(_pinAnimationController.forward());
  }

  void _onMapIdle(AppMapController controller) {
    if (_isProgrammaticCameraMove) return;
    _hasUserPannedMap = true;
    unawaited(_updateCenterFromCamera(controller));
  }

  Future<void> _updateCenterFromCamera(AppMapController controller) async {
    if (!mounted) return;
    final center = await MapProvider.getCameraCenter(controller);
    if (!mounted || _isProgrammaticCameraMove) return;
    unawaited(_reverseGeocode(center.latitude, center.longitude));
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (!mounted) return;
    final requestId = ++_geocodeRequestId;
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _address = 'Locating...';
      _subAddress = '';
      _isGeocoding = true;
    });
    final place = await MapProvider.getPlaceFromCoordinates(lat, lng);
    if (mounted && requestId == _geocodeRequestId) {
      final placeName = place?.displayName.trim() ?? '';
      final fullAddress = place?.fullAddress.trim() ?? '';
      final addressParts = fullAddress
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      final title = placeName.isNotEmpty
          ? placeName
          : addressParts.firstOrNull ?? 'Unknown location';
      setState(() {
        _address = title;
        _subAddress = formatMapPinSubtitle(place);
        _centerLat = lat;
        _centerLng = lng;
        _isGeocoding = false;
      });
      unawaited(_pinAnimationController.reverse());
    }
  }

  Future<void> _useCurrentLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted || position == null) return;

    _hasUserPannedMap = false;
    setState(() {
      _centerLat = position.latitude;
      _centerLng = position.longitude;
    });

    final controller = _mapController;
    if (controller != null) {
      _isProgrammaticCameraMove = true;
      try {
        await MapProvider.moveCamera(
          controller,
          position.latitude,
          position.longitude,
          zoom: 15.0,
          animate: true,
        );
      } finally {
        _isProgrammaticCameraMove = false;
      }
    }
    if (mounted) {
      unawaited(_reverseGeocode(position.latitude, position.longitude));
    }
  }

  Future<void> _openDestinationSearch() async {
    if (!mounted) return;
    final pickupAddress = [
      if (_address != 'Move the map to select a location' &&
          _address != 'Locating...')
        _address,
      if (_subAddress.isNotEmpty) _subAddress,
    ].join(', ');
    await context.pushNamed(
      BookingRoutes.searchDestination,
      queryParameters: {
        'focus': '1',
        'returnToMapPin': '1',
        if (pickupAddress.isNotEmpty) 'pickupAddress': pickupAddress,
      },
    );
  }

  void _confirmLocation() {
    if (_centerLat == null || _centerLng == null) return;
    final result = Place(
      id: 'pin_${DateTime.now().millisecondsSinceEpoch}',
      name: _address,
      fullAddress: [
        _address,
        if (_subAddress.isNotEmpty) _subAddress,
      ].join(', '),
      latitude: _centerLat!,
      longitude: _centerLng!,
    );
    context.pop(result);
  }

  Widget _getMapView() {
    if (_centerLat == null || _centerLng == null) {
      return const SizedBox.shrink();
    }
    _cachedMapView ??= MapProvider.buildMapView(
      latitude: _centerLat!,
      longitude: _centerLng!,
      zoom: 15.0,
      onMapCreated: _onMapCreated,
      onCameraChanged: _onCameraChanged,
      onMapIdle: _onMapIdle,
    );
    return _cachedMapView!;
  }

  @override
  Widget build(BuildContext context) {
    if (_centerLat == null || _centerLng == null) {
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
          elevation: 0,
          leading: Center(
            child: _buildTripBackButton(context, () => context.pop()),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.colorScheme.onSurface,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          _getMapView(),
          Center(
            child: AnimatedBuilder(
              animation: _pinAnimationController,
              builder: (context, child) {
                final lift = Curves.easeOut.transform(
                  _pinAnimationController.value,
                );
                return Transform.translate(
                  offset: Offset(
                    0,
                    -(MapSelectionMarkerWidget.height / 2) - (5 * lift),
                  ),
                  child: child,
                );
              },
              child: Hero(
                tag: widget.flow == MapPinFlow.savedPlace
                    ? BookingRoutes.savedPlaceMapPinHeroTag
                    : BookingRoutes.mapPinHeroTag,
                child: const MapSelectionMarkerWidget(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                height: 52,
                child: widget.flow == MapPinFlow.savedPlace
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTripBackButton(
                          context,
                          () => context.pop(),
                        ),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            left: EasyRideSize.minimumTouchTarget + 8,
                            right: EasyRideSize.minimumTouchTarget + 8,
                            child: _buildDestinationSearchField(context),
                          ),
                          Positioned(
                            left: 0,
                            top: 3,
                            child: _buildTripBackButton(
                              context,
                              () => context.pop(),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                EasyRideLayout.pagePadding,
                10,
                EasyRideLayout.pagePadding,
                MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(EasyRideRadius.sheet),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 34,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.16,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.map_pin,
                          color: context.colorScheme.onSurface,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup location',
                              style: TextStyle(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.62,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _address,
                              style: TextStyle(
                                color: context.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_subAddress.isNotEmpty)
                              Text(
                                _subAddress,
                                style: TextStyle(
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.58),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    button: true,
                    label: 'Use my current location',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(EasyRideRadius.sm),
                      onTap: _useCurrentLocation,
                      child: SizedBox(
                        height: 38,
                        child: Row(
                          children: [
                            Text(
                              'Use my current location',
                              style: TextStyle(
                                color: context.colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevron_right,
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.62,
                              ),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: EasyRideSize.controlHeight,
                    child: FilledButton(
                      onPressed: _isGeocoding ? null : _confirmLocation,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        disabledBackgroundColor: context.colorScheme.primary
                            .withValues(alpha: 0.45),
                        disabledForegroundColor: context.colorScheme.onPrimary
                            .withValues(alpha: 0.7),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        _isGeocoding
                            ? 'Locating...'
                            : 'Confirm pickup location',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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

  Widget _buildDestinationSearchField(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search destination',
      hint: 'Opens destination search',
      child: Hero(
        tag: 'search_bar_field',
        child: Material(
          color: context.colorScheme.surface.withValues(alpha: 0),
          child: InkWell(
            onTap: () => unawaited(_openDestinationSearch()),
            borderRadius: BorderRadius.circular(EasyRideRadius.pill),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                border: Border.all(color: context.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(EasyRideRadius.pill),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: EasyRideSize.minimumTouchTarget,
                    height: EasyRideSize.minimumTouchTarget,
                    child: Center(
                      child: Icon(
                        LucideIcons.search,
                        color: context.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search destination',
                    style: TextStyle(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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
}

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: context.colorScheme.surface,
      elevation: 2,
      shadowColor: context.colorScheme.onSurface.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: EasyRideSize.minimumTouchTarget,
          height: EasyRideSize.minimumTouchTarget,
          child: Center(
            child: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}

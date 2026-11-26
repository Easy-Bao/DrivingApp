import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/formatters/map_pin_address_formatter.dart';
import 'package:passenger/src/features/booking/presentation/widgets/map_pin_bottom_sheet.dart';
import 'package:passenger/src/features/booking/presentation/widgets/map_selection_marker.dart';

enum MapPinFlow { pickup, savedPlace }

extension MapPinFlowCopy on MapPinFlow {
  String get locationLabel => switch (this) {
    MapPinFlow.pickup => 'Pickup location',
    MapPinFlow.savedPlace => 'Saved place location',
  };

  String get confirmationLabel => switch (this) {
    MapPinFlow.pickup => 'Confirm pickup location',
    MapPinFlow.savedPlace => 'Confirm saved place location',
  };
}

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
  bool _isOpeningDestinationSearch = false;
  bool _isPopping = false;
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
    final lat = _centerLat;
    final lng = _centerLng;
    if (lat != null && lng != null) {
      unawaited(_reverseGeocode(lat, lng));
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
        _popOnce();
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
        final controller = _mapController;
        if (controller != null) {
          _isProgrammaticCameraMove = true;
          try {
            await MapProvider.moveCamera(
              controller,
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
      final lat = _centerLat;
      final lng = _centerLng;
      if (lat != null && lng != null) {
        unawaited(_reverseGeocode(lat, lng));
      }
    }
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    final lat = _centerLat;
    final lng = _centerLng;
    if (lat != null && lng != null) {
      _isProgrammaticCameraMove = true;
      unawaited(
        MapProvider.moveCamera(
          controller,
          lat,
          lng,
          zoom: 15.0,
        ).whenComplete(() => _isProgrammaticCameraMove = false),
      );
      if (!_hasUserPannedMap) {
        unawaited(_reverseGeocode(lat, lng));
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
    final place = await () async {
      try {
        return await MapProvider.getPlaceFromCoordinates(lat, lng);
      } catch (_) {
        return null;
      }
    }();
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
    final position = await () async {
      try {
        return await LocationService.getCurrentPosition();
      } catch (_) {
        return null;
      }
    }();
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
    if (!mounted || _isOpeningDestinationSearch) return;
    _isOpeningDestinationSearch = true;
    final pickupAddress = [
      if (_address != 'Move the map to select a location' &&
          _address != 'Locating...')
        _address,
      if (_subAddress.isNotEmpty) _subAddress,
    ].join(', ');
    try {
      await context.pushNamed(
        BookingRoutes.searchDestination,
        queryParameters: {
          'focus': '1',
          'returnToMapPin': '1',
          if (pickupAddress.isNotEmpty) 'pickupAddress': pickupAddress,
        },
      );
    } finally {
      _isOpeningDestinationSearch = false;
    }
  }

  void _popOnce([Object? result]) {
    if (!mounted || _isPopping) return;
    _isPopping = true;
    context.pop(result);
  }

  void _confirmLocation() {
    final lat = _centerLat;
    final lng = _centerLng;
    if (lat == null || lng == null) return;
    final result = Place(
      id: 'pin_${DateTime.now().millisecondsSinceEpoch}',
      name: _address,
      fullAddress: [
        _address,
        if (_subAddress.isNotEmpty) _subAddress,
      ].join(', '),
      latitude: lat,
      longitude: lng,
    );
    _popOnce(result);
  }

  Widget _getMapView(double lat, double lng) {
    return _cachedMapView ??= MapProvider.buildMapView(
      latitude: lat,
      longitude: lng,
      zoom: 15.0,
      onMapCreated: _onMapCreated,
      onCameraChanged: _onCameraChanged,
      onMapIdle: _onMapIdle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = _centerLat;
    final lng = _centerLng;
    if (lat == null || lng == null) {
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: AppBar(
          leading: Center(child: AppMapBackButton(onPressed: _popOnce)),
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
          _getMapView(lat, lng),
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
                    -(MapSelectionMarker.height / 2) - (5 * lift),
                  ),
                  child: child,
                );
              },
              child: widget.flow == MapPinFlow.savedPlace
                  ? const MapSelectionMarker()
                  : const Hero(
                      tag: BookingRoutes.mapPinHeroTag,
                      child: MapSelectionMarker(),
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
                        child: AppMapBackButton(onPressed: _popOnce),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            left: AppSize.minimumTouchTarget + 8,
                            right: 0,
                            child: _buildDestinationSearchField(context),
                          ),
                          Positioned(
                            left: 0,
                            top: 3,
                            child: AppMapBackButton(onPressed: _popOnce),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MapPinBottomSheet(
              locationLabel: widget.flow.locationLabel,
              confirmationLabel: widget.flow.confirmationLabel,
              address: _address,
              subAddress: _subAddress,
              isGeocoding: _isGeocoding,
              onUseCurrentLocation: () => unawaited(_useCurrentLocation()),
              onConfirm: _confirmLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSearchField(BuildContext context) {
    final colors = context.colorScheme;
    return Semantics(
      button: true,
      label: 'Search destination',
      hint: 'Opens destination search',
      child: Hero(
        tag: 'search_bar_field',
        child: Material(
          color: colors.surface.withValues(alpha: 0),
          child: InkWell(
            onTap: () => unawaited(_openDestinationSearch()),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSize.minimumTouchTarget,
                    height: AppSize.minimumTouchTarget,
                    child: Center(
                      child: Icon(
                        LucideIcons.search,
                        color: colors.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search destination',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
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

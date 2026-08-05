import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/shared/widgets/map_zoom_controls_widget.dart';
import 'package:shared_core/shared_core.dart';

class MapPinScreen extends StatefulWidget {
  const MapPinScreen({super.key});

  @override
  State<MapPinScreen> createState() => _MapPinScreenState();
}

class _MapPinScreenState extends State<MapPinScreen>
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
      final hasLocationAccess = await LocationPermissionPrompt.ensure(
        context,
        title: 'Use your location for pickup',
        message:
            'We use your location to place the pickup pin accurately. If you prefer not to share it, return and enter a pickup address manually.',
        secondaryLabel: 'Maybe Later',
      );
      if (!hasLocationAccess || !mounted) {
        if (mounted) context.pop();
        return;
      }
    }

    final pos = await LocationService.getCurrentPosition();
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
      final full = place?.fullAddress ?? 'Unknown location';
      final parts = full.split(',');
      setState(() {
        _address = parts.first.trim();
        _subAddress = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
        _centerLat = lat;
        _centerLng = lng;
        _isGeocoding = false;
      });
      unawaited(_pinAnimationController.reverse());
    }
  }

  Future<void> _relocate() async {
    final hasLocationAccess = await LocationPermissionPrompt.ensure(
      context,
      title: 'Locate your pickup point',
      message: 'Allow location access to center the map on your current spot.',
      secondaryLabel: 'Maybe Later',
    );
    if (!hasLocationAccess || !mounted) return;

    final pos = await LocationService.getCurrentPosition();
    if (pos != null && _mapController != null && mounted) {
      _hasUserPannedMap = false;
      _isProgrammaticCameraMove = true;
      try {
        await MapProvider.moveCamera(
          _mapController!,
          pos.latitude,
          pos.longitude,
          zoom: 16.0,
        );
      } finally {
        _isProgrammaticCameraMove = false;
      }
      unawaited(_reverseGeocode(pos.latitude, pos.longitude));
    }
  }

  void _confirmLocation() {
    if (_centerLat == null || _centerLng == null) return;
    final result = PlaceModel(
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
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrow_left,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.surface,
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
                  offset: Offset(0, -34 - (8 * lift)),
                  child: child,
                );
              },
              child: const Hero(tag: 'map_pin_button', child: _CenterPin()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopButton(
                      icon: LucideIcons.arrow_left,
                      onTap: () => context.pop(),
                    ),
                    _TopButton(
                      icon: LucideIcons.locate_fixed,
                      onTap: _relocate,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.borderSide,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.neutralColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.map_pin,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _address,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_subAddress.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _subAddress,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isGeocoding ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isGeocoding ? 'Locating...' : 'Set Pin Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 270,
            child: MapZoomControlsWidget(
              onZoomIn: () {
                if (_mapController != null) {
                  unawaited(MapProvider.zoomIn(_mapController!));
                }
              },
              onZoomOut: () {
                if (_mapController != null) {
                  unawaited(MapProvider.zoomOut(_mapController!));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Center(
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 52,
      height: 68,
      child: CustomPaint(painter: _CenterPinPainter()),
    );
  }
}

class _CenterPinPainter extends CustomPainter {
  const _CenterPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 23);
    final pinPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 22))
      ..moveTo(center.dx - 10, 38)
      ..lineTo(center.dx, size.height)
      ..lineTo(center.dx + 10, 38)
      ..close();

    canvas.drawShadow(pinPath, Colors.black.withValues(alpha: 0.28), 5, true);
    canvas.drawPath(pinPath, Paint()..color = AppTheme.primaryColor);
    canvas.drawCircle(center, 9, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = AppTheme.primaryColor);
  }

  @override
  bool shouldRepaint(covariant _CenterPinPainter oldDelegate) => false;
}

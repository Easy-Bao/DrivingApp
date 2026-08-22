import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:shared_core/shared_core.dart';

class MapPinPage extends StatefulWidget {
  const MapPinPage({super.key});

  @override
  State<MapPinPage> createState() => _MapPinPageState();
}

class _MapPinPageState extends State<MapPinPage>
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
      final rawPlaceName = place?.name.trim() ?? '';
      final fullAddress = place?.fullAddress.trim() ?? '';
      final addressParts = fullAddress
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      final title = placeName.isNotEmpty
          ? placeName
          : addressParts.firstOrNull ?? 'Unknown location';
      if (rawPlaceName.isNotEmpty &&
          addressParts.isNotEmpty &&
          addressParts.first.toLowerCase() == rawPlaceName.toLowerCase()) {
        addressParts.removeAt(0);
      }
      setState(() {
        _address = title;
        _subAddress = addressParts.join(', ');
        _centerLat = lat;
        _centerLng = lng;
        _isGeocoding = false;
      });
      unawaited(_pinAnimationController.reverse());
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
          backgroundColor: AppTheme.surface.withValues(alpha: 0),
          elevation: 0,
          leading: Center(
            child: _buildTripBackButton(context, () => context.pop()),
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
                  offset: Offset(0, -39 - (8 * lift)),
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTripBackButton(context, () => context.pop()),
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.map_pin,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
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
                                fontWeight: FontWeight.w800,
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
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isGeocoding ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.activeControlForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isGeocoding ? 'Locating...' : 'Set location',
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
        ],
      ),
    );
  }
}

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: AppTheme.surface,
      elevation: 2,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor),
          ),
        ),
      ),
    ),
  );
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 64,
      height: 78,
      child: CustomPaint(painter: _CenterPinPainter()),
    );
  }
}

class _CenterPinPainter extends CustomPainter {
  const _CenterPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 26);
    final outerTail = Path()
      ..moveTo(center.dx - 10, 41)
      ..lineTo(center.dx, size.height - 2)
      ..lineTo(center.dx + 10, 41)
      ..close();
    final innerTail = Path()
      ..moveTo(center.dx - 6, 40)
      ..lineTo(center.dx, size.height - 9)
      ..lineTo(center.dx + 6, 40)
      ..close();
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 23))
      ..addPath(outerTail, Offset.zero);

    canvas.drawShadow(
      shadowPath,
      AppTheme.primaryColor.withValues(alpha: 0.28),
      5,
      true,
    );
    canvas.drawPath(outerTail, Paint()..color = AppTheme.surface);
    canvas.drawPath(innerTail, Paint()..color = AppTheme.primaryColor);
    canvas.drawCircle(center, 23, Paint()..color = AppTheme.surface);
    canvas.drawCircle(center, 18, Paint()..color = AppTheme.primaryColor);
    canvas.drawCircle(center, 9, Paint()..color = AppTheme.secondaryColor);
    canvas.drawCircle(center, 4, Paint()..color = AppTheme.primaryColor);
  }

  @override
  bool shouldRepaint(covariant _CenterPinPainter oldDelegate) => false;
}

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/themes/app_themes.dart';

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
  double _centerLat = LocationService.lastPosition?.latitude ?? 0.0;
  double _centerLng = LocationService.lastPosition?.longitude ?? 0.0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    unawaited(_initLocation());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _centerLat = pos.latitude;
        _centerLng = pos.longitude;
      });
      if (_mapController != null) {
        await MapProvider.moveCamera(
          _mapController!,
          _centerLat,
          _centerLng,
          zoom: 15.0,
        );
      }
      unawaited(_reverseGeocode(_centerLat, _centerLng));
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _isGeocoding = true);
    final place = await MapProvider.getPlaceFromCoordinates(lat, lng);
    if (mounted) {
      final full = place?.fullAddress ?? 'Unknown location';
      final parts = full.split(',');
      setState(() {
        _address = parts.first.trim();
        _subAddress = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
        _centerLat = lat;
        _centerLng = lng;
        _isGeocoding = false;
      });
    }
  }

  Future<void> _relocate() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && _mapController != null && mounted) {
      await MapProvider.moveCamera(
        _mapController!,
        pos.latitude,
        pos.longitude,
        zoom: 16.0,
      );
      unawaited(_reverseGeocode(pos.latitude, pos.longitude));
    }
  }

  Future<void> _updatePin() async {
    if (_mapController == null) return;
    final center = await MapProvider.getCameraCenter(_mapController!);
    unawaited(_reverseGeocode(center.latitude, center.longitude));
  }

  void _confirmLocation() {
    final result = PlaceModel(
      id: 'pin_${DateTime.now().millisecondsSinceEpoch}',
      name: _address,
      fullAddress: [
        _address,
        if (_subAddress.isNotEmpty) _subAddress,
      ].join(', '),
      latitude: _centerLat,
      longitude: _centerLng,
    );
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          MapProvider.buildMapView(
            latitude: _centerLat,
            longitude: _centerLng,
            zoom: 15.0,
            onMapCreated: (coordinate) => _mapController = coordinate,
          ),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, _) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -0.785398,
                            child: const Icon(
                              LucideIcons.map_pin,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _TopButton(
                  icon: LucideIcons.arrow_left,
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.map_pin,
                        color: AppTheme.primaryColor,
                        size: 13,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Pin a location',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _TopButton(icon: LucideIcons.locate_fixed, onTap: _relocate),
              ],
            ),
          ),
          Positioned(
            bottom: 232,
            right: 16,
            child: Column(
              children: [
                _MapButton(
                  icon: LucideIcons.plus,
                  onTap: () async {
                    if (_mapController != null) {
                      final coordinate = await MapProvider.getCameraCenter(
                        _mapController!,
                      );
                      await MapProvider.moveCamera(
                        _mapController!,
                        coordinate.latitude,
                        coordinate.longitude,
                        zoom: 17.0,
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                _MapButton(
                  icon: LucideIcons.minus,
                  onTap: () async {
                    if (_mapController != null) {
                      final coordinate = await MapProvider.getCameraCenter(
                        _mapController!,
                      );
                      await MapProvider.moveCamera(
                        _mapController!,
                        coordinate.latitude,
                        coordinate.longitude,
                        zoom: 13.0,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.neutralColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.map_pin,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected location',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.07,
                                color: AppTheme.tertiaryColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (_isGeocoding)
                              Text(
                                'Locating…',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              )
                            else ...[
                              Text(
                                _address,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_subAddress.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _subAddress,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _updatePin,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.refresh_cw,
                            color: AppTheme.tertiaryColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.tertiaryColor.withValues(
                              alpha: 0.2,
                            ),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${_centerLat.toStringAsFixed(4)}° N, '
                            '${_centerLng.toStringAsFixed(4)}° E',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.tertiaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.tertiaryColor.withValues(
                              alpha: 0.2,
                            ),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isGeocoding ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.primaryColor
                            .withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.check, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Confirm location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 17),
      ),
    );
  }
}

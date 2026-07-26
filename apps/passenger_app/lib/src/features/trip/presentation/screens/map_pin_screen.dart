import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:shared_ui/shared_ui.dart';

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
  Timer? _debounceTimer;
  double _centerLat = LocationService.lastPosition?.latitude ?? 0.0;
  double _centerLng = LocationService.lastPosition?.longitude ?? 0.0;

  @override
  void initState() {
    super.initState();
    unawaited(_initLocation());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted && !_hasUserPannedMap) {
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

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (_centerLat != 0.0 && _centerLng != 0.0) {
      unawaited(MapProvider.moveCamera(controller, _centerLat, _centerLng, zoom: 15.0));
      unawaited(_reverseGeocode(_centerLat, _centerLng));
    }
  }

  void _onCameraChanged(AppMapController controller) {
    _hasUserPannedMap = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || _mapController == null) return;
      final center = await MapProvider.getCameraCenter(_mapController!);
      unawaited(_reverseGeocode(center.latitude, center.longitude));
    });
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
      _hasUserPannedMap = false;
      await MapProvider.moveCamera(
        _mapController!,
        pos.latitude,
        pos.longitude,
        zoom: 16.0,
      );
      unawaited(_reverseGeocode(pos.latitude, pos.longitude));
    }
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
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          MapProvider.buildMapView(
            latitude: _centerLat,
            longitude: _centerLng,
            zoom: 15.0,
            onMapCreated: _onMapCreated,
            onCameraChanged: _onCameraChanged,
          ),
          Center(
            child: Hero(
              tag: 'map_pin_button',
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.map_pin,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 12,
                      color: AppTheme.primaryColor,
                    ),
                    Container(
                      width: 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
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
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

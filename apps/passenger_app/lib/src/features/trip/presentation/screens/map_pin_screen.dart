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
  double _centerLat = LocationService.lastPosition?.latitude ?? 0.0;
  double _centerLng = LocationService.lastPosition?.longitude ?? 0.0;

  @override
  void initState() {
    super.initState();
    unawaited(_initLocation());
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
          // 1. Interactive Map View
          MapProvider.buildMapView(
            latitude: _centerLat,
            longitude: _centerLng,
            zoom: 15.0,
            onMapCreated: (coordinate) => _mapController = coordinate,
          ),

          // 2. Center Pin Marker with Hero shared transition
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

          // 3. Top Row Buttons: Back button left, Locate button right (2nd Picture Layout)
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
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

          // 4. Bottom Location Card Container with AppTheme (2nd Picture Layout)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppTheme.neutralColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.map_pin,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tertiaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (_isGeocoding)
                              Text(
                                'Locating…',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                ),
                              )
                            else ...[
                              Text(
                                _address,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_subAddress.isNotEmpty ? "$_subAddress • " : ""}${_centerLat.toStringAsFixed(4)}° N, ${_centerLng.toStringAsFixed(4)}° E',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.tertiaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _updatePin,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppTheme.neutralColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.refresh_cw,
                              color: AppTheme.tertiaryColor,
                              size: 16,
                            ),
                          ),
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
                        disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderSide),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
    );
  }
}

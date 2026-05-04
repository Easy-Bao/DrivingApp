import "package:BaoRide/core/models/place_model.dart";
import "package:BaoRide/core/services/location_service.dart";
import "package:BaoRide/core/services/map_provider.dart";
import "package:BaoRide/core/themes/app_themes.dart";
import "package:flutter/material.dart";
import "package:flutter_lucide/flutter_lucide.dart";
import "package:go_router_modular/go_router_modular.dart";

/// Full-screen map for manually pinning a destination.
/// Center pin stays fixed; map moves underneath. Reverse geocodes on idle.
class MapPinScreen extends StatefulWidget {
  const MapPinScreen({super.key});

  @override
  State<MapPinScreen> createState() => _MapPinScreenState();
}

class _MapPinScreenState extends State<MapPinScreen> {
  AppMapController? _mapController;
  String _address = "Move the map to select a location";
  bool _isGeocoding = false;
  double _centerLat = 7.8307;
  double _centerLng = 123.4370;

  @override
  void initState() {
    super.initState();
    _initLocation();
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
      _reverseGeocode(_centerLat, _centerLng);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _isGeocoding = true);
    final place = await MapProvider.getPlaceFromCoordinates(lat, lng);
    if (mounted) {
      setState(() {
        _address = place?.fullAddress ?? "Unknown location";
        _centerLat = lat;
        _centerLng = lng;
        _isGeocoding = false;
      });
    }
  }

  void _confirmLocation() {
    final result = PlaceModel(
      id: "pin_${DateTime.now().millisecondsSinceEpoch}",
      name: _address.split(',').first,
      fullAddress: _address,
      latitude: _centerLat,
      longitude: _centerLng,
    );
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapProvider.buildMapView(
            latitude: _centerLat,
            longitude: _centerLng,
            zoom: 15.0,
            onMapCreated: (c) {
              _mapController = c;
            },
          ),

          // Center pin icon (fixed)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.map_pin,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  // Pin tail
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.arrow_left,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),

          // Locate me button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                final pos = await LocationService.getCurrentPosition();
                if (pos != null && _mapController != null) {
                  await MapProvider.moveCamera(
                    _mapController!,
                    pos.latitude,
                    pos.longitude,
                    zoom: 16.0,
                  );
                  _reverseGeocode(pos.latitude, pos.longitude);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.locate_fixed,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),

          // Update location button (floating)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  if (_mapController != null) {
                    final center = await MapProvider.getCameraCenter(
                      _mapController!,
                    );
                    _reverseGeocode(center.latitude, center.longitude);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.crosshair,
                        size: 14,
                        color: AppTheme.tertiaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Tap to update pin",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom address card + confirm
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
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
                              "Selected Location",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.tertiaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _isGeocoding
                                ? Text(
                                    "Searching...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _address,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isGeocoding ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Confirm Location",
                        style: TextStyle(
                          fontSize: 15,
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

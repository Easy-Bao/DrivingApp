import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:design_system/design_system.dart';

class const AddCategoryPage({
  super.key,
  this.initialPlace,
  this.initialLabel,
  this.initialIconName,
}) extends StatefulWidget {
  final Place? initialPlace;
  final String? initialLabel;
  final String? initialIconName;

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _controller = TextEditingController();
  IconData selectedIcon = LucideIcons.heart;
  bool _isLocationPinned = false;
  bool _isLoadingLocation = true;
  double _lat = 0.0;
  double _lng = 0.0;
  AppMapController? _mapController;
  mapbox.PointAnnotationManager? _pinAnnotationManager;
  int _pinRequestId = 0;

  final List<IconData> _availableIcons = [
    LucideIcons.heart,
    LucideIcons.users,
    LucideIcons.graduation_cap,
    LucideIcons.store,
    LucideIcons.star,
    LucideIcons.map_pin,
    LucideIcons.house,
    LucideIcons.briefcase,
  ];

  @override
  void initState() {
    super.initState();
    final defaultLabel = widget.initialLabel ?? widget.initialPlace?.name;
    if (defaultLabel != null) {
      _controller.text = defaultLabel;
    }
    if (widget.initialIconName != null) {
      selectedIcon = _iconDataFromName(widget.initialIconName!);
    }
    if (widget.initialPlace != null) {
      _lat = widget.initialPlace!.latitude;
      _lng = widget.initialPlace!.longitude;
      _isLocationPinned = true;
      _isLoadingLocation = false;
    } else {
      unawaited(_initLocation());
    }
  }

  @override
  void dispose() {
    _pinRequestId++;
    unawaited(MapProvider.clearAnnotations(_pinAnnotationManager));
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _isLocationPinned = true;
        _isLoadingLocation = false;
      });
      if (_mapController != null) {
        await MapProvider.moveCamera(_mapController!, _lat, _lng, zoom: 14.0);
        await _syncPinnedMarker();
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isLocationPinned = false;
        _isLoadingLocation = false;
      });
    }
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (_isLocationPinned) {
      unawaited(_syncPinnedMarker());
    }
  }

  Future<void> _syncPinnedMarker() async {
    final controller = _mapController;
    if (!mounted || controller == null || !_isLocationPinned) return;

    final requestId = ++_pinRequestId;
    final existingManager = _pinAnnotationManager;
    if (existingManager != null) {
      await MapProvider.replaceMarker(
        existingManager,
        _lat,
        _lng,
        isOrigin: false,
        color: context.colorScheme.onSurface,
      );
      return;
    }

    final manager = await MapProvider.addMarker(
      controller,
      _lat,
      _lng,
      isOrigin: false,
      color: context.colorScheme.onSurface,
    );
    if (!mounted || requestId != _pinRequestId) {
      await MapProvider.clearAnnotations(manager);
      return;
    }
    _pinAnnotationManager = manager;
  }

  void _handleSave() {
    final label = _controller.text.trim();

    if (label.isEmpty) {
      _showFailureSnackBar('Please enter a name for your shortcut.');
      return;
    }

    if (!_isLocationPinned) {
      _showFailureSnackBar('Please pin a location on the map before saving.');
      return;
    }

    final iconName = _iconNameFromData(selectedIcon);
    final newPlace = SavedPlace(
      label: label,
      iconName: iconName,
      latitude: _lat,
      longitude: _lng,
      savedAddress: widget.initialPlace?.fullAddress ?? label,
    );

    context.pop(newPlace);
  }

  void _showFailureSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _iconNameFromData(IconData icon) {
    if (icon == LucideIcons.heart) return 'heart';
    if (icon == LucideIcons.users) return 'users';
    if (icon == LucideIcons.graduation_cap) return 'graduation_cap';
    if (icon == LucideIcons.store) return 'store';
    if (icon == LucideIcons.star) return 'star';
    if (icon == LucideIcons.house) return 'house';
    if (icon == LucideIcons.briefcase) return 'briefcase';
    return 'map_pin';
  }

  IconData _iconDataFromName(String name) {
    switch (name) {
      case 'heart':
        return LucideIcons.heart;
      case 'users':
        return LucideIcons.users;
      case 'graduation_cap':
        return LucideIcons.graduation_cap;
      case 'store':
        return LucideIcons.store;
      case 'star':
        return LucideIcons.star;
      case 'house':
        return LucideIcons.house;
      case 'briefcase':
        return LucideIcons.briefcase;
      default:
        return LucideIcons.map_pin;
    }
  }

  Widget? _cachedMapView;

  Widget _getMapView() {
    _cachedMapView ??= MapProvider.buildMapView(
      latitude: _lat,
      longitude: _lng,
      zoom: 14.0,
      interactive: true,
      onMapCreated: _onMapCreated,
    );
    return _cachedMapView!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: context.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add place',
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoadingLocation || !_isLocationPinned
                ? null
                : _handleSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoadingLocation
                    ? context.colorScheme.onSurfaceVariant
                    : context.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 350,
                  width: double.infinity,
                  color: context.colorScheme.surfaceContainerHighest,
                  child: _isLoadingLocation
                      ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        )
                      : _isLocationPinned
                      ? _getMapView()
                      : _buildLocationUnavailableState(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      widget.initialPlace?.fullAddress ??
                          (_isLoadingLocation
                              ? 'Finding your location...'
                              : _isLocationPinned
                              ? 'Location pinned'
                              : 'Location unavailable'),
                      style: TextStyle(
                        color: context.colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Name this place',
                    style: TextStyle(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: context.colorScheme.onSurface,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: "e.g. Ate's house",
                      hintStyle: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: context.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Icon',
                    style: TextStyle(
                      color: context.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableIcons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final icon = _availableIcons[index];
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colorScheme.onSurface.withValues(
                                      alpha: 0.1,
                                    )
                                  : context.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? context.colorScheme.onSurface
                                    : context.colorScheme.outlineVariant,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: context.colorScheme.onSurface,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationUnavailableState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.map_pin_off,
            color: context.colorScheme.onSurfaceVariant,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            'Location unavailable',
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/themes/app_themes.dart';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';
import 'package:passenger_app/src/shared/widgets/custom_toast.dart';

class PassengerAddCategoryScreen extends StatefulWidget {
  final Function(SavedPlace) onSave;
  final PlaceModel? initialPlace;

  const PassengerAddCategoryScreen({
    super.key,
    required this.onSave,
    this.initialPlace,
  });

  @override
  State<PassengerAddCategoryScreen> createState() =>
      _PassengerAddCategoryScreenState();
}

class _PassengerAddCategoryScreenState
    extends State<PassengerAddCategoryScreen> {
  final TextEditingController _controller = TextEditingController();
  IconData selectedIcon = LucideIcons.map_pin;
  String? _errorMessage;
  bool _isLocationPinned = false;
  double _lat = 0.0;
  double _lng = 0.0;
  AppMapController? _mapController;

  final List<IconData> _availableIcons = [
    LucideIcons.map_pin,
    LucideIcons.house,
    LucideIcons.briefcase,
    LucideIcons.shopping_cart,
    LucideIcons.heart,
    LucideIcons.star,
    LucideIcons.coffee,
    LucideIcons.dumbbell,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Shortcut',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Label Your Shortcut',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Give this place a name like 'Gym' or 'Library'.",
                    style: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _controller,
                    autofocus: false,
                    style: const TextStyle(color: AppTheme.primaryColor),
                    onChanged: (value) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter label...',
                      errorText: _errorMessage,
                      prefixIcon: Icon(
                        selectedIcon,
                        color: AppTheme.primaryColor,
                      ),
                      filled: true,
                      fillColor: AppTheme.neutralColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSide,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSide,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableIcons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.borderSide,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Pin Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.neutralColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isLocationPinned
                            ? Colors.green
                            : AppTheme.borderSide,
                        width: _isLocationPinned ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          MapProvider.buildMapView(
                            latitude: _lat,
                            longitude: _lng,
                            zoom: 14.0,
                            interactive: false,
                            onMapCreated: _onMapCreated,
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Location Pinned',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
                top: 12.0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Shortcut',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPlace != null) {
      _lat = widget.initialPlace!.latitude;
      _lng = widget.initialPlace!.longitude;
      _isLocationPinned = true;
      _controller.text = widget.initialPlace!.name;
    } else {
      unawaited(_initLocation());
    }
  }

  void _handleSave() {
    final label = _controller.text.trim();

    if (label.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a name for your shortcut.';
      });
      return;
    }

    if (!_isLocationPinned) {
      CustomToast.show(
        context,
        'Please pin a location on the map before saving.',
        isError: true,
      );
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final iconName = _iconNameFromData(selectedIcon);
    final newPlace = SavedPlace(
      label: label,
      iconName: iconName,
      latitude: _lat,
      longitude: _lng,
      savedAddress: label,
    );

    widget.onSave(newPlace);
    context.pop();
  }

  String _iconNameFromData(IconData icon) {
    if (icon == LucideIcons.house) return 'house';
    if (icon == LucideIcons.briefcase) return 'briefcase';
    if (icon == LucideIcons.shopping_cart) return 'shopping_cart';
    if (icon == LucideIcons.heart) return 'heart';
    if (icon == LucideIcons.star) return 'star';
    if (icon == LucideIcons.coffee) return 'coffee';
    if (icon == LucideIcons.dumbbell) return 'dumbbell';
    return 'map_pin';
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _isLocationPinned = true;
      });
      if (_mapController != null) {
        await MapProvider.moveCamera(_mapController!, _lat, _lng, zoom: 14.0);
        await MapProvider.addMarker(
          _mapController!,
          _lat,
          _lng,
          isOrigin: false,
        );
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isLocationPinned = true;
      });
    }
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    unawaited(MapProvider.addMarker(controller, _lat, _lng, isOrigin: false));
  }
}

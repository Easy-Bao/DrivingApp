import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class SearchDestinationScreen extends StatefulWidget {
  final String? preselectedRideType;
  final String? pickupAddress;

  const SearchDestinationScreen({
    super.key,
    this.preselectedRideType,
    this.pickupAddress,
  });

  @override
  State<SearchDestinationScreen> createState() =>
      _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  Timer? _debounce;
  List<PlaceModel> _results = [];
  List<PlaceModel> _nearbyPlaces = [];
  bool _isSearching = false;
  bool _isLoadingNearby = true;
  double? _userLat = LocationService.lastPosition?.latitude;
  double? _userLng = LocationService.lastPosition?.longitude;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );

    _focusNode.addListener(_onFocusChanged);
    _searchController.addListener(_onSearchChanged);
    unawaited(_initLocation());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus || _searchController.text.isNotEmpty) {
      unawaited(_expandController.forward());
    } else {
      unawaited(_expandController.reverse());
    }
    setState(() {});
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
      unawaited(_loadNearbyPlaces());
    } else if (_userLat != null && _userLng != null) {
      unawaited(_loadNearbyPlaces());
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (_userLat == null || _userLng == null) {
      if (mounted) {
        setState(() {
          _nearbyPlaces = [];
          _isLoadingNearby = false;
        });
      }
      return;
    }

    final results = await MapProvider.getNearbyPOIs(
      lat: _userLat!,
      lng: _userLng!,
    );

    if (mounted) {
      setState(() {
        _nearbyPlaces = results.take(15).toList();
        _isLoadingNearby = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      if (!_focusNode.hasFocus) {
        unawaited(_expandController.reverse());
      }
      return;
    }

    unawaited(_expandController.forward());
    setState(() => _isSearching = true);
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _performSearch(),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final results = await MapProvider.searchPlaces(
      query,
      lat: _userLat,
      lng: _userLng,
    );
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  void _onPlaceSelected(PlaceModel place) {
    final queryParams = <String, String>{};
    if (widget.preselectedRideType != null) {
      queryParams['rideType'] = widget.preselectedRideType!;
    }
    if (widget.pickupAddress != null) {
      queryParams['pickupAddress'] = widget.pickupAddress!;
    }
    unawaited(
      context.pushNamed(
        'DestinationPreview',
        extra: place,
        queryParameters: queryParams,
      ),
    );
  }

  Future<void> _openMapPin() async {
    final result = await context.pushNamed(TripRoutes.mapPin);
    if (result != null && result is PlaceModel) {
      _onPlaceSelected(result);
    }
  }

  IconData _determinePlaceIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('school') ||
        lower.contains('university') ||
        lower.contains('college') ||
        lower.contains('high')) {
      return LucideIcons.graduation_cap;
    }

    if (lower.contains('hospital') ||
        lower.contains('clinic') ||
        lower.contains('doctor')) {
      return LucideIcons.hospital;
    }

    if (lower.contains('resort') ||
        lower.contains('hotel') ||
        lower.contains('casa') ||
        lower.contains('hostel')) {
      return LucideIcons.building;
    }

    if (lower.contains('bank') || lower.contains('bpi') || lower.contains('bdo')) {
      return LucideIcons.landmark;
    }

    if (lower.contains('cafe') || lower.contains('coffee') || lower.contains('tea')) {
      return LucideIcons.coffee;
    }

    if (lower.contains('store') || lower.contains('robinsons') || lower.contains('mall')) {
      return LucideIcons.store;
    }

    return LucideIcons.map_pin;
  }

  @override
  Widget build(BuildContext context) {
    final defaultLat = _userLat ?? 14.5995;
    final defaultLng = _userLng ?? 120.9842;
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final displayList = hasQuery ? _results : _nearbyPlaces;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      resizeToAvoidBottomInset: false,
      body: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final t = _expandAnimation.value; // 0.0 = resting, 1.0 = expanded

          return Stack(
            children: [
              // 1. Background Map View (Fades out when t -> 1.0)
              Positioned.fill(
                child: Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: IgnorePointer(
                    ignoring: t > 0.5,
                    child: GestureDetector(
                      onTap: () {
                        if (_focusNode.hasFocus) {
                          _focusNode.unfocus();
                        }
                        unawaited(_expandController.reverse());
                      },
                      child: MapProvider.buildMapView(
                        latitude: defaultLat,
                        longitude: defaultLng,
                        zoom: 14.5,
                        interactive: true,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Full-Screen Surface Overlay when expanded (t > 0)
              if (t > 0)
                Positioned.fill(
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Container(color: AppTheme.surface),
                  ),
                ),

              // 3. Foreground Safe Layout Column (Zero Overflow Guarantee)
              SafeArea(
                child: Column(
                  children: [
                    // Top Search Header Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Separate Back Button (Visible when resting, fades out as controls merge)
                          if (t < 0.8)
                            Opacity(
                              opacity: (1.0 - (t / 0.8)).clamp(0.0, 1.0),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    if (_focusNode.hasFocus) {
                                      _focusNode.unfocus();
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.borderSide,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.arrow_left,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Search Bar Container Pill (Expands to full width when focused)
                          Expanded(
                            child: Hero(
                              tag: 'search_bar_field',
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(36),
                                    border: Border.all(
                                      color: AppTheme.borderSide,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08 * (1 - t),
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Internal Left Icon: Back arrow when focused/expanded, Search icon when resting
                                      GestureDetector(
                                        onTap: () {
                                          if (_focusNode.hasFocus) {
                                            _focusNode.unfocus();
                                          } else if (t > 0.5) {
                                            unawaited(
                                              _expandController.reverse(),
                                            );
                                          } else {
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            t > 0.5
                                                ? LucideIcons.arrow_left
                                                : LucideIcons.search,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _focusNode,
                                          autofocus: false,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Search destination',
                                            hintStyle: TextStyle(
                                              fontSize: 15,
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.4),
                                              fontWeight: FontWeight.w400,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      if (_searchController.text.isNotEmpty)
                                        GestureDetector(
                                          onTap: () =>
                                              _searchController.clear(),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(
                                              LucideIcons.x,
                                              size: 18,
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),

                                      // Internal Right Icon: Map pin icon when expanded
                                      if (t > 0.5)
                                        GestureDetector(
                                          onTap: _openMapPin,
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.neutralColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                LucideIcons.map_pin,
                                                color: AppTheme.primaryColor,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Separate Map Pin Button (Visible when resting, fades out as controls merge)
                          if (t < 0.8)
                            Opacity(
                              opacity: (1.0 - (t / 0.8)).clamp(0.0, 1.0),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: GestureDetector(
                                  onTap: _openMapPin,
                                  child: Hero(
                                    tag: 'map_pin_button',
                                    child: Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.borderSide,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.map_pin,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Search Results / Nearby Places List Container
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: t == 0 ? 120 : 0),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: t == 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(28),
                                )
                              : BorderRadius.zero,
                          boxShadow: [
                            if (t == 0)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t == 0)
                              Center(
                                child: Container(
                                  width: 38,
                                  height: 4,
                                  margin: const EdgeInsets.only(
                                    top: 14,
                                    bottom: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.borderSide,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Text(
                                hasQuery ? 'SEARCH RESULTS' : 'NEARBY PLACES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: _isSearching || _isLoadingNearby
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : displayList.isEmpty
                                  ? Center(
                                      child: Text(
                                        hasQuery
                                            ? 'No places found'
                                            : 'No nearby places found',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.4),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: displayList.length,
                                      separatorBuilder: (_, _) => const Divider(
                                        height: 1,
                                        color: AppTheme.borderSide,
                                      ),
                                      itemBuilder: (context, index) {
                                        final place = displayList[index];
                                        final icon = _determinePlaceIcon(
                                          place.name,
                                        );
                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                          leading: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.neutralColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                icon,
                                                color: AppTheme.primaryColor,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            place.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            place.distanceKm != null
                                                ? '${place.distanceKm!.toStringAsFixed(1)} km away'
                                                : place.category ?? 'Nearby POI',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.4),
                                              fontSize: 13,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            LucideIcons.map_pin,
                                            size: 18,
                                            color: AppTheme.primaryColor,
                                          ),
                                          onTap: () => _onPlaceSelected(place),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/booking/trip_routes.dart';
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

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<PlaceModel> _results = [];
  List<PlaceModel> _nearbyPlaces = [];
  bool _isSearching = false;
  bool _isLoadingNearby = true;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    unawaited(_initLocation());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      _userLat = pos.latitude;
      _userLng = pos.longitude;
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
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(
      const Duration(milliseconds: 400),
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

    if (lower.contains('clothes') || lower.contains('beauty')) {
      return LucideIcons.shirt;
    }

    if (lower.contains('petron') ||
        lower.contains('shell') ||
        lower.contains('phoenix')) {
      return LucideIcons.fuel;
    }

    return LucideIcons.map_pin;
  }

  bool _isAccentIcon(IconData icon) {
    return icon == LucideIcons.building;
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final displayList = hasQuery ? _results : _nearbyPlaces;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  LucideIcons.arrow_left,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Hero(
                  tag: 'search_bar_field',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderSide),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.search,
                            color: AppTheme.primaryColor.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.primaryColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search destination',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openMapPin,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSide),
                  ),
                  child: const Icon(
                    LucideIcons.map_pin,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              hasQuery ? 'SEARCH RESULTS' : 'NEARBY PLACES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
            ),
          ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasQuery
                              ? LucideIcons.search_x
                              : LucideIcons.map_pin_off,
                          size: 40,
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasQuery
                              ? 'No places found'
                              : 'No nearby places found',
                          style: TextStyle(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayList.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppTheme.borderSide),
                    itemBuilder: (context, index) {
                      final place = displayList[index];
                      final calculatedIcon = _determinePlaceIcon(place.name);
                      final treatAsAccent = _isAccentIcon(calculatedIcon);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: treatAsAccent
                                ? const Color(0xFFFDF0ED)
                                : AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            calculatedIcon,
                            color: treatAsAccent
                                ? const Color(0xFFE15A3E)
                                : AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            place.category ?? 'Place',
                            style: TextStyle(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: place.distanceKm != null
                            ? Text(
                                '${place.distanceKm!.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => _onPlaceSelected(place),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

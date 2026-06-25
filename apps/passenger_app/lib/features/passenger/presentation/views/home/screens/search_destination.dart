import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:passenger_app/core/services/location_service.dart';
import 'package:passenger_app/core/services/map_provider.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({super.key});

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
    _initLocation();
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
      _loadNearbyPlaces();
    } else {
      _userLat = 7.8307;
      _userLng = 123.4370;
      _loadNearbyPlaces();
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
    context.pushNamed('DestinationPreview', extra: place);
  }

  void _openMapPin() async {
    final result = await context.pushNamed('MapPin');
    if (result != null && result is PlaceModel) {
      _onPlaceSelected(result);
    }
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
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Hero(
            tag: 'search_bar_field',
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    Container(
                      height: 24,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                    GestureDetector(
                      onTap: _openMapPin,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.map_pin,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppTheme.borderSide),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              hasQuery ? 'Search Results' : 'Nearby Places',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                letterSpacing: 1.2,
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
                        Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      final place = displayList[index];
                      return _buildPlaceTile(place);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceTile(PlaceModel place) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      leading: Container(
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
      title: Text(
        place.name,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        place.fullAddress,
        style: TextStyle(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: place.distanceKm != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${place.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tertiaryColor,
                ),
              ),
            )
          : const Icon(
              LucideIcons.chevron_right,
              size: 16,
              color: AppTheme.borderSide,
            ),
      onTap: () => _onPlaceSelected(place),
    );
  }
}

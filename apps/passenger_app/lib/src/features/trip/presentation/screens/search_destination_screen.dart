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
      duration: const Duration(milliseconds: 350),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.fastOutSlowIn,
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
    if (_userLat != null && _userLng != null) {
      unawaited(_loadNearbyPlaces());
    }
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
      unawaited(_loadNearbyPlaces());
    } else if (_userLat == null || _userLng == null) {
      if (mounted) {
        setState(() => _isLoadingNearby = false);
      }
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (_userLat == null || _userLng == null) return;

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

    if (lower.contains('bank') ||
        lower.contains('bpi') ||
        lower.contains('bdo')) {
      return LucideIcons.landmark;
    }

    if (lower.contains('cafe') ||
        lower.contains('coffee') ||
        lower.contains('tea')) {
      return LucideIcons.coffee;
    }

    if (lower.contains('store') ||
        lower.contains('robinsons') ||
        lower.contains('mall')) {
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
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final t = _expandAnimation.value;

            final containerLeft = (1.0 - t) * 56.0;
            final containerTop = (1.0 - t) * (topPadding + 10.0);
            final containerRight = (1.0 - t) * 56.0;
            final containerHeight =
                52.0 +
                t *
                    (screenSize.height -
                        (1.0 - t) * (topPadding + 10.0) -
                        52.0);
            final containerRadius = (1.0 - t) * 36.0;

            return Stack(
              children: [
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
                if (t > 0.01)
                  Positioned(
                    left: containerLeft,
                    top: containerTop,
                    right: containerRight,
                    height: containerHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(containerRadius),
                      child: Material(
                        color: AppTheme.surface,
                        elevation: 8 * t,
                        child: Container(
                          color: AppTheme.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: t * (topPadding + 62.0)),
                              if (t > 0.2)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    6,
                                  ),
                                  child: Text(
                                    hasQuery
                                        ? 'SEARCH RESULTS'
                                        : 'NEARBY PLACES',
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
                              if (t > 0.2)
                                Expanded(
                                  child: Opacity(
                                    opacity: ((t - 0.2) / 0.8).clamp(0.0, 1.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child:
                                          (_isSearching ||
                                              (_isLoadingNearby && !hasQuery))
                                           ? SkeletonListWidget(
                                               padding: EdgeInsets.fromLTRB(
                                                 16,
                                                 4,
                                                 16,
                                                 bottomPadding + 16,
                                               ),
                                               itemCount: displayList.isNotEmpty
                                                   ? displayList.length
                                                   : null,
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
                                              padding: EdgeInsets.fromLTRB(
                                                16,
                                                4,
                                                16,
                                                bottomPadding + 16,
                                              ),
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemCount: displayList.length,
                                              separatorBuilder: (_, _) =>
                                                  const Divider(
                                                    height: 1,
                                                    color: AppTheme.borderSide,
                                                  ),
                                              itemBuilder: (context, index) {
                                                final place =
                                                    displayList[index];
                                                final icon =
                                                    _determinePlaceIcon(
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
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: AppTheme
                                                              .neutralColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Center(
                                                      child: Icon(
                                                        icon,
                                                        color: AppTheme
                                                            .primaryColor,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    place.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    place.distanceKm != null
                                                        ? '${place.distanceKm!.toStringAsFixed(1)} km away'
                                                        : place.category ??
                                                              'Nearby POI',
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .primaryColor
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  trailing: const Icon(
                                                    LucideIcons.map_pin,
                                                    size: 18,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                  onTap: () =>
                                                      _onPlaceSelected(place),
                                                );
                                              },
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (1.0 - t) * 56.0,
                              ),
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
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              transitionBuilder:
                                                  (child, animation) =>
                                                      ScaleTransition(
                                                        scale: animation,
                                                        child: child,
                                                      ),
                                              child: Icon(
                                                t > 0.4
                                                    ? LucideIcons.arrow_left
                                                    : LucideIcons.search,
                                                key: ValueKey(t > 0.4),
                                                color: AppTheme.primaryColor,
                                                size: 20,
                                              ),
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
                                        if (t >= 0.4)
                                          Opacity(
                                            opacity: ((t - 0.4) / 0.6).clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            child: Transform.scale(
                                              scale: ((t - 0.4) / 0.6).clamp(
                                                0.0,
                                                1.0,
                                              ),
                                              child: GestureDetector(
                                                onTap: _openMapPin,
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: AppTheme
                                                              .neutralColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Center(
                                                      child: Icon(
                                                        LucideIcons.map_pin,
                                                        color: AppTheme
                                                            .primaryColor,
                                                        size: 18,
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
                                ),
                              ),
                            ),
                          ),
                          if (t < 0.4)
                            Positioned(
                              left: 0,
                              top: 3,
                              child: Opacity(
                                opacity: (1.0 - (t / 0.4)).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: (1.0 - t * 0.5).clamp(0.0, 1.0),
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
                            ),
                          if (t < 0.4)
                            Positioned(
                              right: 0,
                              top: 3,
                              child: Opacity(
                                opacity: (1.0 - (t / 0.4)).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: (1.0 - t * 0.5).clamp(0.0, 1.0),
                                  child: GestureDetector(
                                    onTap: _openMapPin,
                                    child: Hero(
                                      tag: 'map_pin_button',
                                      child: Material(
                                        color: Colors.transparent,
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
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

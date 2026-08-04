import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/shared/widgets/map_zoom_controls_widget.dart';
import 'package:shared_core/shared_core.dart';
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
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  Timer? _debounce;
  List<PlaceModel> _results = [];
  List<PlaceModel> _allNearbyPlaces = [];
  int _displayedCount = 10;
  int _currentNearbyPage = 1;
  bool _isLoadingMoreNearby = false;
  bool _hasMoreNearbyPages = true;
  bool _isSearching = false;
  bool _isLoadingNearby = true;
  final Map<String, double> _drivingDistances = {};
  final Set<String> _drivingDistanceRequests = {};
  int _searchRequestId = 0;
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
    _scrollController.addListener(_onScroll);
    unawaited(_initLocation());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(MapProvider.clearAnnotations(_currentLocationMarker));
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_searchController.text.trim().isNotEmpty) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 160) {
      _loadNextLazyBatch();
    }
  }

  void _loadNextLazyBatch() {
    if (_searchController.text.trim().isNotEmpty) return;

    if (_displayedCount < _allNearbyPlaces.length) {
      setState(() {
        _displayedCount = (_displayedCount + 10).clamp(
          0,
          _allNearbyPlaces.length,
        );
      });
      return;
    }

    if (!_isLoadingMoreNearby && _hasMoreNearbyPages) {
      unawaited(_fetchMoreNearbyFromApi());
    }
  }

  Future<void> _fetchMoreNearbyFromApi() async {
    if (_userLat == null || _userLng == null || _isLoadingMoreNearby) return;
    setState(() => _isLoadingMoreNearby = true);

    final nextPage = _currentNearbyPage + 1;
    try {
      final moreResults = await MapProvider.getNearbyPOIs(
        lat: _userLat!,
        lng: _userLng!,
        page: nextPage,
      );

      if (mounted) {
        _currentNearbyPage = nextPage;
        if (moreResults.isEmpty) {
          _hasMoreNearbyPages = false;
        } else {
          var addedCount = 0;
          for (final item in moreResults) {
            final isDup = _allNearbyPlaces.any(
              (p) =>
                  p.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
                  item.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
            );
            if (!isDup) {
              _allNearbyPlaces.add(item);
              addedCount++;
            }
          }
          _allNearbyPlaces.sort((a, b) {
            final double distA = a.distanceKm ?? double.maxFinite;
            final double distB = b.distanceKm ?? double.maxFinite;
            return distA.compareTo(distB);
          });
          _displayedCount = _allNearbyPlaces.length;
          if (addedCount == 0 || moreResults.length < 10) {
            _hasMoreNearbyPages = false;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreNearby = false);
      }
    }
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
    _userLat ??= LocationService.lastPosition?.latitude;
    _userLng ??= LocationService.lastPosition?.longitude;
    if (_userLat != null && _userLng != null) {
      unawaited(_loadNearbyPlaces());
    }

    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
      if (_mapController != null) {
        await MapProvider.moveCamera(
          _mapController!,
          pos.latitude,
          pos.longitude,
          zoom: 14.5,
          animate: false,
        );
        unawaited(_updateCurrentLocationMarker(pos.latitude, pos.longitude));
      }
      unawaited(_loadNearbyPlaces());
    }
  }

  Future<void> _loadNearbyPlaces() async {
    final lat = _userLat;
    final lng = _userLng;
    if (lat == null || lng == null) {
      if (mounted) setState(() => _isLoadingNearby = false);
      return;
    }

    try {
      final results = await MapProvider.getNearbyPOIs(
        lat: lat,
        lng: lng,
        page: 1,
      );

      if (mounted) {
        setState(() {
          _allNearbyPlaces = results;
          _displayedCount = results.length;
          _currentNearbyPage = 1;
          _hasMoreNearbyPages = results.length == 10;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingNearby = false);
      }
    }
  }

  void _onSearchChanged() {
    _searchRequestId++;
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
    final requestId = _searchRequestId;

    final localMatches = _allNearbyPlaces
        .where((place) => _matchesSearchQuery(place, query))
        .toList();

    final apiResults = await MapProvider.searchPlaces(
      query,
      lat: _userLat,
      lng: _userLng,
    );

    final mergedResults = <PlaceModel>[...localMatches];
    for (final res in apiResults.where(
      (place) =>
          (place.distanceKm == null || place.distanceKm! <= 10.0) &&
          _matchesSearchQuery(place, query),
    )) {
      final isDuplicate = mergedResults.any(
        (m) =>
            m.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
                res.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ||
            ((m.latitude - res.latitude).abs() < 0.0001 &&
                (m.longitude - res.longitude).abs() < 0.0001),
      );
      if (!isDuplicate) {
        mergedResults.add(res);
      }
    }

    if (mounted && requestId == _searchRequestId) {
      setState(() {
        _results = _sortPlacesByDistance(mergedResults);
        _isSearching = false;
      });
      unawaited(_loadDrivingDistances(mergedResults, requestId));
    }
  }

  Future<void> _loadDrivingDistances(
    List<PlaceModel> places,
    int requestId,
  ) async {
    if (_userLat == null || _userLng == null) return;

    for (final place in places) {
      final key = _placeKey(place);
      if (_drivingDistances.containsKey(key) ||
          !_drivingDistanceRequests.add(key)) {
        continue;
      }

      try {
        final route = await MapProvider.getRoute(
          _userLat!,
          _userLng!,
          place.latitude,
          place.longitude,
        );
        if (route != null && mounted) {
          setState(() {
            _drivingDistances[key] = route.distanceKm;
            if (requestId == _searchRequestId) {
              _results = _sortPlacesByDistance(_results);
            }
          });
        }
      } catch (_) {
      } finally {
        _drivingDistanceRequests.remove(key);
      }
    }
  }

  String _placeKey(PlaceModel place) {
    return '${place.id}:${place.latitude.toStringAsFixed(5)}:${place.longitude.toStringAsFixed(5)}';
  }

  bool _matchesSearchQuery(PlaceModel place, String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return false;

    final searchableText = _normalizeSearchText(
      '${place.name} ${place.fullAddress}',
    );
    final compactQuery = _compactSearchText(query);
    final compactSearchableText = _compactSearchText(
      '${place.name} ${place.fullAddress}',
    );
    if (compactQuery.isNotEmpty &&
        compactSearchableText.contains(compactQuery)) {
      return true;
    }
    if (searchableText.contains(normalizedQuery)) return true;

    final queryTokens = normalizedQuery.split(' ');
    final searchableTokens = searchableText.split(' ');
    return queryTokens.every(
      (queryToken) => searchableTokens.any(
        (searchableToken) => searchableToken.startsWith(queryToken),
      ),
    );
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _compactSearchText(String value) {
    return _normalizeSearchText(value).replaceAll(' ', '');
  }

  List<PlaceModel> _sortPlacesByDistance(List<PlaceModel> places) {
    final sorted = [...places];
    sorted.sort(
      (a, b) => _distanceForSorting(a).compareTo(_distanceForSorting(b)),
    );
    return sorted;
  }

  double _distanceForSorting(PlaceModel place) {
    return _drivingDistances[_placeKey(place)] ??
        place.distanceKm ??
        double.maxFinite;
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

  Widget? _cachedMapView;
  AppMapController? _mapController;
  dynamic _currentLocationMarker;
  int _locationMarkerRequestId = 0;

  Widget _getMapView(double lat, double lng) {
    _cachedMapView ??= MapProvider.buildMapView(
      latitude: lat,
      longitude: lng,
      zoom: 14.5,
      interactive: true,
      onMapCreated: (controller) {
        _mapController = controller;
        unawaited(_updateCurrentLocationMarker(lat, lng));
      },
    );
    return _cachedMapView!;
  }

  Future<void> _updateCurrentLocationMarker(double lat, double lng) async {
    final controller = _mapController;
    if (controller == null) return;
    final requestId = ++_locationMarkerRequestId;

    final previousMarker = _currentLocationMarker;
    _currentLocationMarker = null;
    if (previousMarker != null) {
      await MapProvider.clearAnnotations(previousMarker);
    }

    final marker = await MapProvider.addMarker(
      controller,
      lat,
      lng,
      isOrigin: true,
      label: 'Current location\nYou are here',
    );
    if (mounted && requestId == _locationMarkerRequestId) {
      _currentLocationMarker = marker;
    } else {
      await MapProvider.clearAnnotations(marker);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userLat == null || _userLng == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrow_left,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }
    final defaultLat = _userLat!;
    final defaultLng = _userLng!;
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final displayList = hasQuery
        ? _results
        : _allNearbyPlaces.take(_displayedCount).toList();
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
                        child: _getMapView(defaultLat, defaultLng),
                      ),
                    ),
                  ),
                ),
                if (t < 0.5)
                  Positioned(
                    right: 16,
                    bottom: 80,
                    child: Opacity(
                      opacity: (1.0 - t * 2.0).clamp(0.0, 1.0),
                      child: MapZoomControlsWidget(
                        onZoomIn: () {
                          if (_mapController != null) {
                            unawaited(MapProvider.zoomIn(_mapController!));
                          }
                        },
                        onZoomOut: () {
                          if (_mapController != null) {
                            unawaited(MapProvider.zoomOut(_mapController!));
                          }
                        },
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
                                              itemCount: 8,
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
                                              controller: _scrollController,
                                              padding: EdgeInsets.fromLTRB(
                                                16,
                                                4,
                                                16,
                                                bottomPadding + 16,
                                              ),
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(
                                                    parent:
                                                        BouncingScrollPhysics(),
                                                  ),
                                              itemCount:
                                                  displayList.length +
                                                  (!hasQuery &&
                                                          _isLoadingMoreNearby
                                                      ? 1
                                                      : 0),
                                              separatorBuilder: (_, _) =>
                                                  const Divider(
                                                    height: 1,
                                                    color: AppTheme.borderSide,
                                                  ),
                                              itemBuilder: (context, index) {
                                                if (index ==
                                                    displayList.length) {
                                                  return const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 12,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 44,
                                                          height: 44,
                                                          child: Center(
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2.0,
                                                                color: AppTheme
                                                                    .primaryColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 14),
                                                        Expanded(
                                                          child: Text(
                                                            'Loading more nearby places...',
                                                            style: TextStyle(
                                                              color: AppTheme
                                                                  .borderSide,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
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
                                                    _formatPlaceDistance(place),
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
                          Positioned(
                            right: 0,
                            top: 3,
                            child: Opacity(
                              opacity: (1.0 - (t / 0.4)).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: (1.0 - t * 0.5).clamp(0.0, 1.0),
                                child: GestureDetector(
                                  onTap: _openMapPin,
                                  child: SizedBox(
                                    width: 46,
                                    height: 46,
                                    child: Hero(
                                      tag: 'map_pin_button',
                                      child: FittedBox(
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
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
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

  String _formatDistance(double distanceKm) {
    if (distanceKm < 0.1) {
      return '${(distanceKm * 1000).round()} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  String _formatPlaceDistance(PlaceModel place) {
    final key = _placeKey(place);
    final drivingDistance = _drivingDistances[key];
    if (drivingDistance != null) {
      return _formatDistance(drivingDistance);
    }
    if (_drivingDistanceRequests.contains(key)) {
      return 'Calculating route...';
    }
    return place.distanceKm != null
        ? _formatDistance(place.distanceKm!)
        : place.category ?? 'Nearby POI';
  }
}

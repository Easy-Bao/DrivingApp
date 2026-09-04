import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/search_destination_formatters.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const SearchDestinationPage({
  super.key,
  this.preselectedRideType,
  this.pickupAddress,
}) extends StatefulWidget {
  final String? preselectedRideType;
  final String? pickupAddress;

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState()
    extends State<SearchDestinationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _mapFadeAnimation;
  late final Animation<double> _resultsFadeAnimation;
  late final Animation<double> _mapPinFadeAnimation;
  late final Animation<double> _collapsedControlsFadeAnimation;

  Timer? _debounce;
  List<Place> _results = [];
  List<Place> _allNearbyPlaces = [];
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
    _mapFadeAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(_expandAnimation);
    _resultsFadeAnimation = _fadeAfter(0.2);
    _mapPinFadeAnimation = _fadeAfter(0.4);
    _collapsedControlsFadeAnimation = _fadeUntil(0.4);

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

  Animation<double> _fadeAfter(double start) {
    return Tween<double>(
      begin: 0,
      end: 1,
    ).chain(CurveTween(curve: Interval(start, 1))).animate(_expandAnimation);
  }

  Animation<double> _fadeUntil(double end) {
    return Tween<double>(
      begin: 1,
      end: 0,
    ).chain(CurveTween(curve: Interval(0, end))).animate(_expandAnimation);
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
          final previousCount = _allNearbyPlaces.length;
          _allNearbyPlaces = mergeUniqueDestinationResults(
            _allNearbyPlaces,
            moreResults,
          );
          final addedCount = _allNearbyPlaces.length - previousCount;
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

    final hasLocationAccess =
        await LocationService.getAccessState() == LocationAccessState.ready;
    final pos = hasLocationAccess
        ? await LocationService.getCurrentPosition()
        : null;
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
        .where((place) => destinationMatchesSearchQuery(place, query))
        .toList();

    final apiResults = await MapProvider.searchPlaces(
      query,
      lat: _userLat,
      lng: _userLng,
    );

    final mergedResults = mergeUniqueDestinationResults(
      localMatches,
      apiResults.where(
        (place) =>
            (place.distanceKm == null || place.distanceKm! <= 10.0) &&
            destinationMatchesSearchQuery(place, query),
      ),
      compareCoordinates: true,
    );

    if (mounted && requestId == _searchRequestId) {
      setState(() {
        _results = sortDestinationsByDistance(mergedResults, _drivingDistances);
        _isSearching = false;
      });
      unawaited(_loadDrivingDistances(mergedResults, requestId));
    }
  }

  Future<void> _loadDrivingDistances(List<Place> places, int requestId) async {
    if (_userLat == null || _userLng == null) return;

    final pendingPlaces = <Place>[];
    final pendingKeys = <String>[];
    for (final place in places) {
      final key = destinationPlaceKey(place);
      if (_drivingDistances.containsKey(key) ||
          !_drivingDistanceRequests.add(key)) {
        continue;
      }
      pendingPlaces.add(place);
      pendingKeys.add(key);
    }

    if (pendingPlaces.isEmpty) return;

    try {
      final distances = await MapProvider.getDrivingDistances(
        originLat: _userLat!,
        originLng: _userLng!,
        destinations: [
          for (final place in pendingPlaces)
            (lat: place.latitude, lng: place.longitude),
        ],
      );
      if (distances == null || !mounted) return;

      final resolvedDistances = <String, double>{};
      for (var index = 0; index < pendingKeys.length; index++) {
        if (index >= distances.length) break;
        final distance = distances[index];
        if (distance.isFinite && distance >= 0) {
          resolvedDistances[pendingKeys[index]] = distance;
        }
      }
      if (resolvedDistances.isEmpty) return;

      setState(() {
        _drivingDistances.addAll(resolvedDistances);
        if (requestId == _searchRequestId) {
          _results = sortDestinationsByDistance(_results, _drivingDistances);
        }
      });
    } finally {
      for (final key in pendingKeys) {
        _drivingDistanceRequests.remove(key);
      }
    }
  }

  void _onPlaceSelected(Place place) {
    final queryParams = <String, String>{};
    if (widget.preselectedRideType != null) {
      queryParams['rideType'] = widget.preselectedRideType!;
    }
    if (widget.pickupAddress != null) {
      queryParams['pickupAddress'] = widget.pickupAddress!;
    }
    if (_userLat != null && _userLng != null) {
      queryParams['pickupLat'] = _userLat!.toString();
      queryParams['pickupLng'] = _userLng!.toString();
    }
    unawaited(
      context.pushNamed(
        BookingRoutes.rideSelection,
        extra: place,
        queryParameters: queryParams,
      ),
    );
  }

  Future<void> _openMapPin() async {
    final result = await context.pushNamed(BookingRoutes.mapPin);
    if (result != null && result is Place) {
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
  mapbox.PointAnnotationManager? _currentLocationMarker;
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
      color: TripMapMarkerStyle.ownLocation,
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
        backgroundColor: context.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
          elevation: 0,
          leading: Center(
            child: _buildTripBackButton(context, () => context.pop()),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.colorScheme.onSurface,
          ),
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
      backgroundColor: context.colorScheme.surface,
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
                  child: FadeTransition(
                    opacity: _mapFadeAnimation,
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
                if (t > 0.01)
                  Positioned(
                    left: containerLeft,
                    top: containerTop,
                    right: containerRight,
                    height: containerHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(containerRadius),
                      child: Material(
                        color: context.colorScheme.surface,
                        elevation: 8 * t,
                        child: Container(
                          color: context.colorScheme.surface,
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
                                        ? 'Search Results'
                                        : 'Nearby Places',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: context.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              if (t > 0.2)
                                Expanded(
                                  child: FadeTransition(
                                    opacity: _resultsFadeAnimation,
                                    child: Material(
                                      color: context.colorScheme.surface
                                          .withValues(alpha: 0),
                                      child:
                                          (_isSearching ||
                                              (_isLoadingNearby && !hasQuery))
                                          ? Skeletonizer.zone(
                                              child: ListView.separated(
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
                                                itemCount: 8,
                                                separatorBuilder: (_, _) =>
                                                    Divider(
                                                      height: 1,
                                                      color: context
                                                          .colorScheme
                                                          .outlineVariant,
                                                    ),
                                                itemBuilder: (_, _) =>
                                                    const ListTile(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      leading: Bone.circle(
                                                        size: 44,
                                                      ),
                                                      title: Bone.text(
                                                        width: 130,
                                                        fontSize: 15,
                                                      ),
                                                      subtitle: Bone.text(
                                                        width: 90,
                                                        fontSize: 13,
                                                      ),
                                                      trailing: Bone.icon(
                                                        size: 18,
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : displayList.isEmpty
                                          ? Center(
                                              child: Text(
                                                hasQuery
                                                    ? 'No places found'
                                                    : 'No nearby places found',
                                                style: TextStyle(
                                                  color: context
                                                      .colorScheme
                                                      .onSurface
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
                                                  Divider(
                                                    height: 1,
                                                    color: context
                                                        .colorScheme
                                                        .outlineVariant,
                                                  ),
                                              itemBuilder: (context, index) {
                                                if (index ==
                                                    displayList.length) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
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
                                                                color: context
                                                                    .colorScheme
                                                                    .onSurface,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 14,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'Loading more nearby places...',
                                                            style: TextStyle(
                                                              color: context
                                                                  .colorScheme
                                                                  .outlineVariant,
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
                                                    decoration: BoxDecoration(
                                                      color: context
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        icon,
                                                        color: context
                                                            .colorScheme
                                                            .onSurface,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    place.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                      color: context
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    formatDestinationPlaceDistance(
                                                      place,
                                                      _drivingDistances,
                                                      _drivingDistanceRequests,
                                                    ),
                                                    style: TextStyle(
                                                      color: context
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  trailing: Icon(
                                                    LucideIcons.map_pin,
                                                    size: 18,
                                                    color: context
                                                        .colorScheme
                                                        .onSurface,
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
                                  color: context.colorScheme.surface.withValues(
                                    alpha: 0,
                                  ),
                                  child: Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(36),
                                      border: Border.all(
                                        color:
                                            context.colorScheme.outlineVariant,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: context.colorScheme.onSurface
                                              .withValues(
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
                                                color: context
                                                    .colorScheme
                                                    .onSurface,
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
                                            style: TextStyle(
                                              fontSize: 15,
                                              color:
                                                  context.colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Search destination',
                                              hintStyle: TextStyle(
                                                fontSize: 15,
                                                color: context
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.4),
                                                fontWeight: FontWeight.w400,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder:
                                                  InputBorder.none,
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
                                                color: context
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                        if (t >= 0.4)
                                          FadeTransition(
                                            opacity: _mapPinFadeAnimation,
                                            child: Transform.scale(
                                              scale: ((t - 0.4) / 0.6).clamp(
                                                0.0,
                                                1.0,
                                              ),
                                              child: GestureDetector(
                                                onTap: _openMapPin,
                                                child: Material(
                                                  color: context
                                                      .colorScheme
                                                      .surface
                                                      .withValues(alpha: 0),
                                                  child: Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: context
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        LucideIcons.map_pin,
                                                        color: context
                                                            .colorScheme
                                                            .onSurface,
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
                              child: FadeTransition(
                                opacity: _collapsedControlsFadeAnimation,
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
                                        color: context.colorScheme.surface,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: context.colorScheme.onSurface
                                                .withValues(alpha: 0.08),
                                            blurRadius: 15,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.arrow_left,
                                          color: context.colorScheme.onSurface,
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
                            child: FadeTransition(
                              opacity: _collapsedControlsFadeAnimation,
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
                                          color: context.colorScheme.surface
                                              .withValues(alpha: 0),
                                          child: Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color:
                                                  context.colorScheme.surface,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: context
                                                    .colorScheme
                                                    .outlineVariant,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: context
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Icon(
                                                LucideIcons.map_pin,
                                                color: context
                                                    .colorScheme
                                                    .onSurface,
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
}

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: context.colorScheme.surface,
      elevation: 2,
      shadowColor: context.colorScheme.onSurface.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}

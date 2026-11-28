import 'dart:async';
import 'dart:developer' as developer;

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/bloc/search_destination/search_destination_cubit.dart';
import 'package:passenger/src/features/booking/presentation/widgets/search_destination_bar.dart';
import 'package:passenger/src/features/booking/presentation/widgets/search_destination_results.dart';

class const SearchDestinationPage({
  super.key,
  this.pickupAddress,
  this.autofocusSearch = false,
  this.returnToMapPin = false,
  this.lifecycleCoordinator,
}) extends StatefulWidget {
  static const searchDebounceDuration = Duration(milliseconds: 300);

  final String? pickupAddress;
  final bool autofocusSearch;
  final bool returnToMapPin;
  final AppLifecycleCoordinator? lifecycleCoordinator;

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

bool shouldShowDestinationResultsLoading({
  required bool isSearching,
  required bool hasQuery,
}) {
  return isSearching && hasQuery;
}

bool shouldHideInitialDestinationResults({
  required bool isLoadingNearby,
  required bool hasQuery,
  required bool hasResults,
}) {
  return !hasQuery && isLoadingNearby && !hasResults;
}

double destinationSearchAvailableHeight({
  required double screenHeight,
  required double keyboardInset,
}) {
  final availableHeight = screenHeight - keyboardInset;
  return availableHeight < 52 ? 52 : availableHeight;
}

class _SearchDestinationPageState()
    extends State<SearchDestinationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final SearchDestinationCubit _cubit;
  late final AnimationController _expandController;
  late final CurvedAnimation _expandAnimation;
  late final Animation<double> _mapFadeAnimation;
  late final Animation<double> _resultsFadeAnimation;
  late final Animation<double> _mapPinFadeAnimation;
  late final Animation<double> _collapsedControlsFadeAnimation;
  StreamSubscription<AppLifecycleStatus>? _lifecycleSubscription;

  Timer? _debounce;
  bool _isOpeningMapPin = false;
  bool _isOpeningRideSelection = false;
  bool _isPopping = false;
  Widget? _cachedMapView;
  AppMapController? _mapController;
  bool _mapReady = false;
  MapPointAnnotationManager? _currentLocationMarker;
  int _locationMarkerRequestId = 0;

  @override
  void initState() {
    super.initState();
    final lastPosition = LocationService.lastPosition;
    _cubit = SearchDestinationCubit(
      initialLatitude: lastPosition?.latitude,
      initialLongitude: lastPosition?.longitude,
    );
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
    _lifecycleSubscription = widget.lifecycleCoordinator?.changes.listen(
      _onLifecycleChanged,
    );
    if (widget.autofocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
    unawaited(_initLocation());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_lifecycleSubscription?.cancel());
    unawaited(MapProvider.clearAnnotations(_currentLocationMarker));
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _expandAnimation.dispose();
    _expandController.dispose();
    unawaited(_cubit.close());
    super.dispose();
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

  bool _isAuthenticated() {
    if (!mounted) return false;
    try {
      return BlocProvider.of<SessionBloc>(context).state
          is AuthenticatedSession;
    } catch (_) {
      return false;
    }
  }

  void _onLifecycleChanged(AppLifecycleStatus status) {
    if (status != AppLifecycleStatus.foreground || !mounted) return;
    unawaited(_reloadAfterForeground());
  }

  Future<void> _reloadAfterForeground() async {
    if (!mounted) return;
    if (_searchController.text.trim().isEmpty) {
      if (_cubit.state.userLatitude == null ||
          _cubit.state.userLongitude == null) {
        await _initLocation();
        return;
      }
      _cubit.markNearbyRefreshing();
      await _cubit.loadNearbyPlaces();
      return;
    }
    await _cubit.performSearch(
      _searchController.text,
      isAuthenticated: _isAuthenticated(),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_searchController.text.trim().isNotEmpty) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 160) {
      _cubit.loadNextNearbyBatch();
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

  void _handleSearchBackTap() {
    if (widget.returnToMapPin) {
      _popOnce();
      return;
    }
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else if (_expandController.value > 0.5) {
      unawaited(_expandController.reverse());
    } else {
      _popOnce();
    }
  }

  void _popOnce() {
    if (!mounted || _isPopping) return;
    _isPopping = true;
    context.pop();
  }

  Future<void> _initLocation() async {
    final initialLat = _cubit.state.userLatitude;
    final initialLng = _cubit.state.userLongitude;
    if (initialLat != null && initialLng != null) {
      unawaited(_cubit.loadNearbyPlaces());
    }

    final hasLocationAccess =
        await LocationService.getAccessState() == LocationAccessState.ready;
    final position = hasLocationAccess
        ? await LocationService.getCurrentPosition()
        : null;
    if (position != null && mounted) {
      final shouldReloadNearby =
          initialLat == null ||
          initialLng == null ||
          (position.latitude - initialLat).abs() >= 0.0005 ||
          (position.longitude - initialLng).abs() >= 0.0005;
      _cubit.updateUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        markLoadingNearby: shouldReloadNearby,
      );
      final controller = _mapController;
      if (controller != null) {
        try {
          await MapProvider.moveCamera(
            controller,
            position.latitude,
            position.longitude,
            zoom: 14.5,
            animate: false,
          );
          if (!mounted) return;
          unawaited(
            _updateCurrentLocationMarker(position.latitude, position.longitude),
          );
        } catch (error, stackTrace) {
          developer.log(
            'Unable to move destination search camera to user location.',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      if (mounted && shouldReloadNearby) {
        unawaited(_cubit.loadNearbyPlaces());
      }
    } else if (mounted &&
        (_cubit.state.userLatitude == null ||
            _cubit.state.userLongitude == null)) {
      _cubit.markNearbyLoadStopped();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _cubit.clearSearch();
      if (!_focusNode.hasFocus) {
        unawaited(_expandController.reverse());
      }
      setState(() {});
      return;
    }

    unawaited(_expandController.forward());
    final requestId = _cubit.startSearchPending();
    setState(() {});
    _debounce = Timer(
      SearchDestinationPage.searchDebounceDuration,
      () => unawaited(
        _cubit.performSearch(
          _searchController.text,
          isAuthenticated: _isAuthenticated(),
          requestId: requestId,
        ),
      ),
    );
  }

  Future<void> _onPlaceSelected(Place place) async {
    if (!mounted || _isOpeningRideSelection) return;
    _isOpeningRideSelection = true;
    _clearSearchAfterSelection();
    final queryParams = <String, String>{};
    final pickupAddress = widget.pickupAddress;
    if (pickupAddress != null) {
      queryParams['pickupAddress'] = pickupAddress;
    }
    final userLat = _cubit.state.userLatitude;
    final userLng = _cubit.state.userLongitude;
    if (userLat != null && userLng != null) {
      queryParams['pickupLat'] = userLat.toString();
      queryParams['pickupLng'] = userLng.toString();
    }
    try {
      await context.pushNamed(
        BookingRoutes.rideSelection,
        extra: place,
        queryParameters: queryParams,
      );
    } finally {
      _isOpeningRideSelection = false;
    }
  }

  void _clearSearchAfterSelection() {
    _debounce?.cancel();
    _debounce = null;
    _searchController.clear();
    _cubit.clearSearch();
  }

  Future<void> _openMapPin() async {
    if (widget.returnToMapPin) {
      _popOnce();
      return;
    }
    if (!mounted || _isOpeningMapPin) return;
    _isOpeningMapPin = true;
    try {
      final result = await context.pushNamed(
        BookingRoutes.mapPin,
        queryParameters: const {'destination': '1'},
      );
      if (mounted && result is Place) {
        unawaited(_onPlaceSelected(result));
      }
    } finally {
      _isOpeningMapPin = false;
    }
  }

  Widget _getMapView(double lat, double lng) {
    return _cachedMapView ??= MapProvider.buildMapView(
      latitude: lat,
      longitude: lng,
      zoom: 14.5,
      interactive: true,
      onMapCreated: (controller) {
        _mapController = controller;
        _locationMarkerRequestId++;
        _currentLocationMarker = null;
        if (_mapReady) setState(() => _mapReady = false);
      },
      onMapLoaded: () {
        if (!mounted) return;
        setState(() => _mapReady = true);
        unawaited(
          _updateCurrentLocationMarker(
            _cubit.state.userLatitude ?? lat,
            _cubit.state.userLongitude ?? lng,
          ),
        );
      },
    );
  }

  Future<void> _updateCurrentLocationMarker(double lat, double lng) async {
    final controller = _mapController;
    if (controller == null || !_mapReady) return;
    final requestId = ++_locationMarkerRequestId;

    final previousMarker = _currentLocationMarker;
    _currentLocationMarker = null;
    if (previousMarker != null) {
      await MapProvider.clearAnnotations(previousMarker);
    }
    if (!mounted || !_mapReady || requestId != _locationMarkerRequestId) return;

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
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final topPadding = mediaPadding.top;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottomPadding = mediaPadding.bottom;
    final bottomPadding = viewInsetsBottom > systemBottomPadding
        ? viewInsetsBottom
        : systemBottomPadding;
    final availableHeight = destinationSearchAvailableHeight(
      screenHeight: screenSize.height,
      keyboardInset: viewInsetsBottom,
    );
    final hasQuery = _searchController.text.trim().isNotEmpty;

    final mapLayer =
        BlocBuilder<SearchDestinationCubit, SearchDestinationState>(
          bloc: _cubit,
          buildWhen: (previous, current) =>
              (previous.userLatitude == null) !=
                  (current.userLatitude == null) ||
              (previous.userLongitude == null) !=
                  (current.userLongitude == null),
          builder: (context, state) {
            final lat = state.userLatitude;
            final lng = state.userLongitude;
            return GestureDetector(
              onTap: () {
                if (_focusNode.hasFocus) {
                  _focusNode.unfocus();
                }
                unawaited(_expandController.reverse());
              },
              child: lat != null && lng != null
                  ? _getMapView(lat, lng)
                  : ColoredBox(
                      color: context.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            );
          },
        );

    final resultsPanelContent =
        BlocBuilder<SearchDestinationCubit, SearchDestinationState>(
          bloc: _cubit,
          builder: (context, state) {
            final displayList = state.visiblePlaces(hasQuery: hasQuery);
            final shouldShowLoading = shouldShowDestinationResultsLoading(
              isSearching: state.isSearching,
              hasQuery: hasQuery,
            );
            final shouldHideInitialResults =
                shouldHideInitialDestinationResults(
                  isLoadingNearby: state.isLoadingNearby,
                  hasQuery: hasQuery,
                  hasResults: displayList.isNotEmpty,
                );
            if (shouldHideInitialResults) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Text(
                    hasQuery ? 'Search Results' : 'Nearby Places',
                    style: context.textStyles.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _resultsFadeAnimation,
                    child: Material(
                      color: context.colorScheme.surface.withValues(alpha: 0),
                      child: SearchDestinationResults(
                        places: displayList,
                        hasQuery: hasQuery,
                        isLoading: shouldShowLoading,
                        isLoadingMoreNearby: state.isLoadingMoreNearby,
                        bottomPadding: bottomPadding,
                        scrollController: _scrollController,
                        drivingDistances: state.drivingDistances,
                        drivingDistanceRequests: state.drivingDistanceRequests,
                        onPlaceSelected: _onPlaceSelected,
                        errorMessage: hasQuery
                            ? state.searchError
                            : state.nearbyError,
                        onRetry: () {
                          MapProvider.clearLookupCaches();
                          if (hasQuery) {
                            final requestId = _cubit.startSearchPending();
                            unawaited(
                              _cubit.performSearch(
                                _searchController.text,
                                isAuthenticated: _isAuthenticated(),
                                requestId: requestId,
                              ),
                            );
                          } else if (_cubit.state.userLatitude == null ||
                              _cubit.state.userLongitude == null) {
                            unawaited(_initLocation());
                          } else {
                            _cubit.markNearbyRefreshing();
                            unawaited(_cubit.loadNearbyPlaces());
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: _mapFadeAnimation,
                child: AnimatedBuilder(
                  animation: _expandAnimation,
                  child: mapLayer,
                  builder: (_, child) => IgnorePointer(
                    ignoring: _expandAnimation.value > 0.5,
                    child: child,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _expandAnimation,
                child: resultsPanelContent,
                builder: (context, resultsChild) {
                  final t = _expandAnimation.value;
                  final containerLeft = (1.0 - t) * 56.0;
                  final containerTop = (1.0 - t) * (topPadding + 10.0);
                  final containerRight = (1.0 - t) * 56.0;
                  final containerHeight =
                      52.0 +
                      t *
                          (availableHeight -
                              (1.0 - t) * (topPadding + 10.0) -
                              52.0);
                  final containerRadius = (1.0 - t) * 36.0;

                  return Stack(
                    children: [
                      if (t > 0.01)
                        Positioned(
                          left: containerLeft,
                          top: containerTop,
                          right: containerRight,
                          height: containerHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              containerRadius,
                            ),
                            child: Material(
                              color: context.colorScheme.surface,
                              elevation: 8 * t,
                              child: ColoredBox(
                                color: context.colorScheme.surface,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: t * (topPadding + 62.0)),
                                    if (t > 0.2) Expanded(child: resultsChild!),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      SearchDestinationBar(
                        expandProgress: t,
                        mapPinFadeAnimation: _mapPinFadeAnimation,
                        collapsedControlsFadeAnimation:
                            _collapsedControlsFadeAnimation,
                        searchController: _searchController,
                        focusNode: _focusNode,
                        onBackTap: _handleSearchBackTap,
                        onOpenMapPin: () => unawaited(_openMapPin()),
                        onClearSearch: _searchController.clear,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

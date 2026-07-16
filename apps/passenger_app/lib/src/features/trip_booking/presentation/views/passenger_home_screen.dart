import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/services/bid_session_service.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/passenger_home_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/passenger_home_state.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/saved_places_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/saved_places_state.dart';
import 'package:passenger_app/src/features/trip_booking/trip_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

/// Evaluates the selected saved place shortcut. If coordinates are present,
/// it pushes the DestinationPreview screen directly. Otherwise, it launches
/// the SearchDestination screen to allow the user to lookup the coordinates.
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  int _notificationCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 12),
                          _buildLocationRow(),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildChipRow(),
                          const SizedBox(height: 24),
                          _buildRecentActivityHeader(),
                          Expanded(child: _buildRecentActivityList()),
                        ],
                      ),
                    ),
                    if (_bidSessionService.isActive)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: _buildBackgroundSearchingBanner(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  StreamSubscription? _locationSubscription;
  StreamSubscription? _bidSessionStatusSubscription;
  StreamSubscription? _bidSessionMatchSubscription;
  late BidSessionService _bidSessionService;

  @override
  void dispose() {
    if (_locationSubscription != null) {
      unawaited(_locationSubscription!.cancel());
    }
    if (_bidSessionStatusSubscription != null) {
      unawaited(_bidSessionStatusSubscription!.cancel());
    }
    if (_bidSessionMatchSubscription != null) {
      unawaited(_bidSessionMatchSubscription!.cancel());
    }
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideIn = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bidSessionService = getIt<BidSessionService>();
    _bidSessionService.setForeground(false);

    _bidSessionStatusSubscription = _bidSessionService.statusStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _bidSessionMatchSubscription = _bidSessionService.driverFoundStream.listen((
      driverMatchResult,
    ) {
      if (mounted) {
        CustomToast.show(context, 'Driver Found! Matching you now.');
        context.pushReplacementNamed(
          'DriverMatched',
          extra: driverMatchResult.toNavigationExtra(),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(_entranceController.forward());
      await _loadSavedPlaces();
      await _initLocationAndLoadData();
      unawaited(_loadNotificationCount());
    });
  }

  Widget _buildBackgroundSearchingBanner() {
    final activeTrip = _bidSessionService.trip;
    return GestureDetector(
      onTap: () {
        if (activeTrip != null) {
          unawaited(
            context.pushNamed(
              TripRoutes.findingDriver,
              extra: {
                'rideType': activeTrip.rideType,
                'fare': activeTrip.fare,
                'destination': activeTrip.destination,
                'distance': activeTrip.distance,
                'duration': activeTrip.duration,
                'pickupAddress': activeTrip.pickupAddress,
              },
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Searching for drivers...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeTrip?.destination.name ?? 'Destination',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final passengerId = prefs.getString('passenger_id') ?? '';
      if (passengerId.isEmpty) return;
      final raw = await getIt<PassengerApiService>().fetchNotifications(
        passengerId,
      );
      final unread = raw.where((n) {
        final map = n as Map<String, dynamic>;
        final type = map['type'] as String? ?? '';
        final isRead = map['isRead'] as bool? ?? false;
        return (type == 'ride' || type == 'driver' || type == 'chat') &&
            !isRead;
      }).length;
      if (mounted) setState(() => _notificationCount = unread);
    } catch (_) {}
  }

  Widget _buildAddChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.borderSide,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.plus, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            'Add',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow() {
    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildShimmerChip(),
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ...state.places.asMap().entries.map((entry) {
                final index = entry.key;
                final place = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _handleSavedPlaceTap(place),
                    onLongPress: () => _showChipOptions(index, place.label),
                    child: _buildSavedPlaceChip(place),
                  ),
                );
              }),
              GestureDetector(
                onTap: _openAddCategoryScreen,
                child: _buildAddChip(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EasyRide',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
                letterSpacing: -1.5,
              ),
            ),
            Text(
              'Ready to ride today?',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  LucideIcons.bell,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () => context.pushNamed(TripRoutes.notifications),
              ),
            ),
            if (_notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _notificationCount > 99 ? '99+' : '$_notificationCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevron_right,
        size: 16,
        color: AppTheme.borderSide,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLocationRow() {
    return BlocBuilder<PassengerHomeCubit, PassengerHomeState>(
      buildWhen: (prev, curr) => prev.currentAddress != curr.currentAddress,
      builder: (context, state) {
        return Row(
          children: [
            const Icon(
              LucideIcons.map_pin,
              size: 14,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                state.currentAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        TextButton(
          onPressed: () => context.pushNamed(TripRoutes.viewAllSuggestions),
          child: const Text(
            'View all',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    return BlocBuilder<PassengerHomeCubit, PassengerHomeState>(
      buildWhen: (prev, curr) =>
          prev.recentLocations != curr.recentLocations ||
          prev.isLoading != curr.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: state.recentLocations.isEmpty
                ? 3
                : state.recentLocations.length,
            itemBuilder: (_, _) => _buildShimmerListItem(),
          );
        }
        if (state.recentLocations.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 36,
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 12),
                Text(
                  'No recent trips yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: state.recentLocations.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Colors.grey[100]),
          itemBuilder: (context, index) {
            final location = state.recentLocations[index];
            final title = location['title'] as String? ?? '';
            IconData icon;
            if (title.contains('Luz') || title.contains('Plaza')) {
              icon = LucideIcons.circle_play;
            } else if (title.contains('Supermarket') ||
                title.contains('Robinson')) {
              icon = LucideIcons.store;
            } else if (title.contains('Coffee') || title.contains("Bo's")) {
              icon = LucideIcons.coffee;
            } else if (title.contains('Capital') || title.contains('Gaisano')) {
              icon = LucideIcons.shopping_bag;
            } else {
              icon = LucideIcons.map_pin;
            }
            return _buildLocationItem(
              icon: icon,
              title: title,
              subtitle: location['subtitle'] as String? ?? 'Previous Trip',
              onTap: () => _openActivityDetail(location),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedPlaceChip(SavedPlace place) {
    final hasLocation = place.hasLocation;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasLocation
            ? AppTheme.secondaryColor.withValues(alpha: 0.25)
            : AppTheme.surface,
        border: Border.all(
          color: hasLocation ? AppTheme.secondaryColor : AppTheme.borderSide,
          width: hasLocation ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFromName(place.iconName),
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            place.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          if (hasLocation) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF285A48),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        final address = BlocProvider.of<PassengerHomeCubit>(
          context,
        ).state.currentAddress;
        unawaited(
          context.pushNamed(
            TripRoutes.searchDestination,
            queryParameters: {'pickupAddress': address},
          ),
        );
      },
      child: Hero(
        tag: 'search_bar_field',
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSide),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.search,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Enter destination',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerChip() {
    return Container(
      width: 90,
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildShimmerListItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFromName(String name) => SavedPlacesCubit.iconFromName(name);

  Future<void> _initLocationAndLoadData() async {
    if (!mounted) return;
    final cubit = BlocProvider.of<PassengerHomeCubit>(context);

    final hasPermission = await LocationService.checkAndRequestPermission();
    if (!hasPermission) {
      final serviceEnabled = await LocationService.isServiceEnabled();
      if (mounted) {
        final message = serviceEnabled
            ? 'Location permission denied. Enable it in Settings to see your location.'
            : 'Location services are disabled. Enable them in Settings.';
        CustomToast.show(context, message, isError: true);
      }
      return;
    }

    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      await cubit.loadHomeData(lat: position.latitude, lng: position.longitude);
    } else {
      if (mounted) {
        CustomToast.show(
          context,
          'Unable to acquire your location. Check GPS signal.',
          isError: true,
        );
      }
    }

    unawaited(_locationSubscription?.cancel());
    _locationSubscription = LocationService.getPositionStream().listen((
      pos,
    ) async {
      if (!mounted) return;
      try {
        await cubit.loadHomeData(lat: pos.latitude, lng: pos.longitude);
      } catch (_) {}
    }, onError: (_) {});
  }

  Future<void> _loadSavedPlaces() async {
    if (!mounted) return;
    await BlocProvider.of<SavedPlacesCubit>(context).loadPlaces();
  }

  Future _openActivityDetail(Map<String, dynamic> location) async {
    await context.pushNamed(TripRoutes.activityDetailMap, extra: location);
  }

  Future _openAddCategoryScreen() async {
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    final selectedPlace = await context.pushNamed(TripRoutes.mapPin);
    if (selectedPlace == null || selectedPlace is! PlaceModel) return;
    if (!mounted) return;
    await context.pushNamed(
      'PassengerAddCategory',
      extra: {
        'onSave': (SavedPlace newPlace) => cubit.addPlace(newPlace),
        'place': selectedPlace,
      },
    );
  }

  Future _showChipOptions(int index, String label) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.borderSide),
            ListTile(
              leading: const Icon(
                LucideIcons.trash_2,
                color: Colors.red,
                size: 20,
              ),
              title: const Text(
                'Remove shortcut',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await BlocProvider.of<SavedPlacesCubit>(
                  context,
                ).removePlace(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleSavedPlaceTap(SavedPlace place) {
    if (!mounted) return;
    if (place.hasLocation) {
      final syntheticPlace = PlaceModel(
        id: 'saved_${place.label.toLowerCase().replaceAll(' ', '_')}',
        name: place.label,
        fullAddress: place.savedAddress ?? place.label,
        latitude: place.latitude!,
        longitude: place.longitude!,
      );
      final address = BlocProvider.of<PassengerHomeCubit>(
        context,
      ).state.currentAddress;
      unawaited(
        context.pushNamed(
          TripRoutes.destinationPreview,
          extra: syntheticPlace,
          queryParameters: {'pickupAddress': address},
        ),
      );
    } else {
      final address = BlocProvider.of<PassengerHomeCubit>(
        context,
      ).state.currentAddress;
      unawaited(
        context.pushNamed(
          TripRoutes.searchDestination,
          queryParameters: {'pickupAddress': address},
        ),
      );
    }
  }
}

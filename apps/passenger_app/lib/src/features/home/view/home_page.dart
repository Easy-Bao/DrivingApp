import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/home/bloc/home/home_cubit.dart';
import 'package:passenger_app/src/features/home/bloc/home/home_state.dart';
import 'package:passenger_app/src/features/home/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger_app/src/features/home/bloc/public_driver_summary/public_driver_summary_state.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/home/view/widgets/pending_booking_banner_widget.dart';
import 'package:passenger_app/src/features/home/view/widgets/public_driver_summary_card_widget.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_state.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/view/saved_place_page.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _locationPollInterval = Duration(seconds: 2);

  StreamSubscription? _locationSubscription;
  Timer? _locationAccessPoller;
  late final BookingBloc _bookingBloc;
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      _buildLocationRow(),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      _buildPendingBookingBanner(),
                      _buildPublicDriverSummary(),
                      const SizedBox(height: 16),
                      _buildChipRow(),
                      const SizedBox(height: 24),
                      _buildRecentActivityHeader(),
                      Expanded(child: _buildRecentActivityList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_locationSubscription != null) {
      unawaited(_locationSubscription!.cancel());
    }
    _locationAccessPoller?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bookingBloc = Modular.get<BookingBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSavedPlaces();
      await _initLocationAndLoadData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshLocationAfterResume());
    }
  }

  Future<void> _refreshLocationAfterResume() async {
    await _initLocationAndLoadData();
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
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _handleSavedPlaceTap(place),
                    onLongPress: () => _showChipOptions(index, place.label),
                    child: _buildSavedPlaceChip(place),
                  ),
                );
              }),
              _buildAddPlaceChip(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingBookingBanner() {
    return BlocBuilder<BookingDraftCubit, BookingDraftState>(
      buildWhen: (previous, current) => previous.draft != current.draft,
      builder: (context, state) {
        final draft = state.draft;
        if (draft == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PendingBookingBannerWidget(
            destinationName: draft.destination.name,
            onContinue: () {
              final pickupAddress = draft.pickupAddress;
              BlocProvider.of<BookingDraftCubit>(context).clear();
              unawaited(
                context.pushNamed(
                  TripRoutes.destinationPreview,
                  extra: draft.destination,
                  queryParameters: {
                    if (pickupAddress != null && pickupAddress.isNotEmpty)
                      'pickupAddress': pickupAddress,
                  },
                ),
              );
            },
            onDismiss: () =>
                BlocProvider.of<BookingDraftCubit>(context).clear(),
          ),
        );
      },
    );
  }

  Widget _buildPublicDriverSummary() {
    return BlocBuilder<PublicDriverSummaryCubit, PublicDriverSummaryState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.summaries != current.summaries,
      builder: (context, state) {
        if (state.summaries.isEmpty || state.isLoading) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PublicDriverSummaryCardWidget(summaries: state.summaries),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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

  Widget _buildShimmerLocationRow() {
    return Row(
      children: [
        const Icon(LucideIcons.map_pin, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Container(
          width: 140,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) =>
          prev.currentAddress != curr.currentAddress ||
          prev.isLoading != curr.isLoading,
      builder: (context, state) {
        Widget content;
        if (state.isLoading) {
          content = _buildShimmerLocationRow();
        } else if (state.currentAddress.isEmpty) {
          content = const Row(
            children: [
              Icon(LucideIcons.map_pin, size: 14, color: AppTheme.primaryColor),
              SizedBox(width: 6),
              Text(
                'Turn on location to set pickup',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          );
        } else {
          content = Row(
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
        }
        return content;
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
          onPressed: () =>
              context.pushNamed(ActivityRoutes.viewAllRecentActivity),
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
    return BlocBuilder<HomeCubit, HomeState>(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No recent trips yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your recent ride history will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
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

  Widget _buildAddPlaceChip() {
    return GestureDetector(
      onTap: () async {
        final cubit = BlocProvider.of<SavedPlacesCubit>(context);
        final selectedPlace = await context.pushNamed(TripRoutes.mapPin);
        if (selectedPlace == null || selectedPlace is! PlaceModel) return;
        if (!mounted) return;
        await context.pushNamed(
          HomeRoutes.addCategory,
          extra: {
            'onSave': (SavedPlace newPlace) => cubit.addPlace(newPlace),
            'place': selectedPlace,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plus,
              size: 16,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Add place',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPlaceChip(SavedPlace place) {
    final hasLocation = place.hasLocation;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: hasLocation
            ? AppTheme.secondaryColor.withValues(alpha: 0.25)
            : AppTheme.surface,
        border: Border.all(
          color: hasLocation ? AppTheme.secondaryColor : AppTheme.borderSide,
          width: hasLocation ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFromName(place.iconName),
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            place.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
        if (_bookingBloc.hasActiveDriverSearch) {
          CustomToast.show(
            context,
            'A driver search is already in progress.',
            isError: true,
          );
          return;
        }
        final address = BlocProvider.of<HomeCubit>(
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
              borderRadius: BorderRadius.circular(36),
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
                  'Search destination',
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

  Future<void> _handleSavedPlaceTap(SavedPlace place) async {
    if (!mounted) return;
    if (place.hasLocation) {
      final syntheticPlace = PlaceModel(
        id: 'saved_${place.label.toLowerCase().replaceAll(' ', '_')}',
        name: place.label,
        fullAddress: place.savedAddress ?? place.label,
        latitude: place.latitude!,
        longitude: place.longitude!,
      );
      final address = BlocProvider.of<HomeCubit>(context).state.currentAddress;
      unawaited(
        context.pushNamed(
          TripRoutes.destinationPreview,
          extra: syntheticPlace,
          queryParameters: {'pickupAddress': address},
        ),
      );
    } else {
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed(TripRoutes.mapPin);
      if (selectedPlace == null || selectedPlace is! PlaceModel) return;
      if (!mounted) return;
      await context.pushNamed(
        HomeRoutes.addCategory,
        extra: {
          'onSave': (SavedPlace newPlace) => cubit.addPlace(newPlace),
          'place': selectedPlace,
          'initialLabel': place.label,
        },
      );
    }
  }

  IconData _iconFromName(String name) => savedPlaceIconFromName(name);

  Future<void> _initLocationAndLoadData() async {
    if (!mounted || _isLoadingLocation) return;
    _isLoadingLocation = true;
    try {
      final cubit = BlocProvider.of<HomeCubit>(context);
      final hasLocationAccess =
          await LocationService.getAccessState() == LocationAccessState.ready;
      if (!hasLocationAccess) {
        _startLocationAccessMonitoring();
        return;
      }

      final position =
          await LocationService.getCurrentPosition() ??
          LocationService.lastPosition;
      if (!mounted || position == null) {
        _startLocationAccessMonitoring();
        return;
      }

      _stopLocationAccessMonitoring();
      await cubit.loadHomeData(lat: position.latitude, lng: position.longitude);
      if (!mounted) return;

      unawaited(_locationSubscription?.cancel());
      _locationSubscription = LocationService.getPositionStream().listen(
        (pos) async {
          if (!mounted) return;
          try {
            await cubit.loadHomeData(lat: pos.latitude, lng: pos.longitude);
          } catch (_) {}
        },
        onError: (_) {
          _startLocationAccessMonitoring();
        },
      );
    } finally {
      _isLoadingLocation = false;
    }
  }

  void _startLocationAccessMonitoring() {
    _locationAccessPoller ??= Timer.periodic(
      _locationPollInterval,
      (_) => unawaited(_initLocationAndLoadData()),
    );
  }

  void _stopLocationAccessMonitoring() {
    _locationAccessPoller?.cancel();
    _locationAccessPoller = null;
  }

  Future<void> _loadSavedPlaces() async {
    if (!mounted) return;
    await BlocProvider.of<SavedPlacesCubit>(context).loadPlaces();
  }

  Future _openActivityDetail(Map<String, dynamic> location) async {
    await context.pushNamed(TripRoutes.activityDetailMap, extra: location);
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
}

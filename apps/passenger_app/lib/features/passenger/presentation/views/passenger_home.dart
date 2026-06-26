import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:fixtures/fixtures.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/passenger_home_cubit.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/passenger_home_state.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/saved_places_cubit.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/saved_places_state.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/models/quick_action_model.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/models/saved_place_model.dart';

/**
 * Primary home screen for the passenger-facing application shell.
 *
 * This screen composes four functional regions: the header (greeting + location
 * chip), the destination search bar, the saved-place shortcut chip row, the
 * quick-action cards (Solo Ride / Share-Bao), and the recent-activity list.
 *
 * State is sourced from two cubits provided by the shell route:
 * - [PassengerHomeCubit]: owns the current-location address and recent-activity list.
 * - [SavedPlacesCubit]: owns the persisted saved-place chips. Navigation callbacks
 *   are injected into the cubit after mount via [attachContext].
 *
 * The chip row is reactive: [BlocBuilder<SavedPlacesCubit, SavedPlacesState>]
 * rebuilds whenever chips are added or removed. Long-pressing a chip presents
 * a bottom sheet with a "Remove" option backed by [SavedPlacesCubit.removePlace].
 */
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  List<QuickActionModel> _quickActions = [];
  List<Map<String, dynamic>> _recentLocationData = [];

  late AnimationController _entranceController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

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

    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _buildQuickActions();
    _buildRecentLocations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachSavedPlacesContext();
      _loadSavedPlaces();
      _initLocationAndLoadData();
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /**
   * Provides the cubit with a live [BuildContext] so it can build navigation
   * callbacks that call [context.pushNamed]. This must be called after the
   * first frame when [context] is fully mounted in the widget tree.
   */
  void _attachSavedPlacesContext() {
    if (!mounted) return;
    BlocProvider.of<SavedPlacesCubit>(context).attachContext(context);
  }

  Future<void> _loadSavedPlaces() async {
    if (!mounted) return;
    await BlocProvider.of<SavedPlacesCubit>(context).loadPlaces();
  }

  void _buildQuickActions() {
    _quickActions = MockData.getQuickActions().map((action) {
      final title = action['title'] ?? '';
      return QuickActionModel(
        icon: _iconFromName(action['iconName'] ?? ''),
        title: title,
        subtitle: action['subtitle'] ?? '',
        onTap: () => context.pushNamed(
          'SearchDestination',
          queryParameters: {'rideType': title},
        ),
      );
    }).toList();
  }

  void _buildRecentLocations() {
    _recentLocationData = MockData.getRecentLocations().map((loc) {
      final title = loc['title'] as String;
      IconData icon;
      if (title.contains('Luz')) {
        icon = LucideIcons.circle_play;
      } else if (title.contains('Supermarket') || title.contains('Robinson')) {
        icon = LucideIcons.store;
      } else if (title.contains('Coffee') || title.contains("Bo's")) {
        icon = LucideIcons.coffee;
      } else if (title.contains('Capital') || title.contains('Gaisano')) {
        icon = LucideIcons.shopping_bag;
      } else {
        icon = LucideIcons.circle_play;
      }
      return {...loc, 'icon': icon};
    }).toList();
  }

  Future<void> _initLocationAndLoadData() async {
    if (!mounted) return;
    final cubit = BlocProvider.of<PassengerHomeCubit>(context);
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      await cubit.loadHomeData(lat: position.latitude, lng: position.longitude);
    } else {
      await cubit.loadHomeData(
        lat: MockData.defaultLat,
        lng: MockData.defaultLng,
      );
    }
  }

  IconData _iconFromName(String name) => SavedPlacesCubit.iconFromName(name);

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /**
   * Opens the AddCategory sheet. On save the returned [SavedPlaceModel] is
   * passed directly to the cubit so the chip row updates and persists
   * without requiring a setState call in this widget.
   */
  void _openAddCategoryScreen() {
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    context.pushNamed(
      'PassengerAddCategory',
      extra: (SavedPlaceModel newPlace) => cubit.addPlace(newPlace),
    );
  }

  /**
   * Long-pressing a chip presents a bottom sheet offering removal.
   * The index is used to call [SavedPlacesCubit.removePlace] which rebuilds
   * the chip row and persists the change.
   */
  void _showChipOptions(int index, String label) {
    showModalBottomSheet(
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
              onTap: () {
                Navigator.pop(context);
                BlocProvider.of<SavedPlacesCubit>(context).removePlace(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openActivityDetail(Map<String, dynamic> location) {
    context.pushNamed('ActivityDetailMap', extra: location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: Padding(
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
                  _buildQuickActionCards(),
                  const SizedBox(height: 32),
                  _buildRecentActivityHeader(),
                  Expanded(child: _buildRecentActivityList()),
                ],
              ),
            ),
          ),
        ),
      ),
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
                icon: const Icon(LucideIcons.bell, color: AppTheme.primaryColor),
                onPressed: () => context.pushNamed('Notifications'),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return BlocBuilder<PassengerHomeCubit, PassengerHomeState>(
      buildWhen: (prev, curr) => prev.currentAddress != curr.currentAddress,
      builder: (context, state) {
        return Row(
          children: [
            const Icon(LucideIcons.map_pin, size: 14, color: AppTheme.primaryColor),
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

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.pushNamed('SearchDestination'),
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
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            _showFeedback('Locating...');
            _initLocationAndLoadData();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.locate_fixed,
              color: AppTheme.neutralColor,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  /**
   * The chip row is rebuilt reactively whenever [SavedPlacesCubit] emits a new
   * state. Each chip supports a long-press to reveal the remove option. The
   * "+ Add" chip is always appended after the saved chips.
   */
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
                    onTap: place.onTap,
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

  /**
   * Renders a saved-place chip. Chips with pinned coordinates show a small
   * green dot indicator and a warm tint, signalling that tapping them will
   * skip the search flow entirely.
   */
  Widget _buildSavedPlaceChip(SavedPlaceModel place) {
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

  Widget _buildAddChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.borderSide, style: BorderStyle.solid),
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

  /**
   * Builds the Solo Ride / Share-Bao cards with a subtle warm gradient
   * background for a premium, elevated feel.
   */
  Widget _buildQuickActionCards() {
    return Row(
      children: _quickActions.asMap().entries.map((entry) {
        final isLast = entry.key == _quickActions.length - 1;
        final action = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: _buildQuickActionCard(
              icon: action.icon,
              title: action.title,
              subtitle: action.subtitle,
              onTap: action.onTap,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.neutralColor,
              AppTheme.secondaryColor.withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
          onPressed: () => context.pushNamed('ViewAllSuggestions'),
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
      buildWhen: (prev, curr) => prev.recentLocations != curr.recentLocations,
      builder: (context, state) {
        final locations = state.recentLocations.isEmpty
            ? _recentLocationData
            : state.recentLocations;
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: locations.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Colors.grey[100]),
          itemBuilder: (context, index) {
            final location = locations[index];
            return _buildLocationItem(
              icon: (location['icon'] ?? LucideIcons.map_pin) as IconData,
              title: location['title'] as String,
              subtitle: location['subtitle'] as String,
              onTap: () => _openActivityDetail(location),
            );
          },
        );
      },
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
}

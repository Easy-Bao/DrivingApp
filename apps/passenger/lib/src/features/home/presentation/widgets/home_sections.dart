import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_state.dart';
import 'package:passenger/src/features/home/presentation/widgets/destination_search_hint.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_empty_state.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_preview.dart';
import 'package:passenger/src/features/home/presentation/widgets/saved_place_quick_actions.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      label: 'Search for a destination',
      hint: 'Opens destination search',
      child: Hero(
        tag: 'search_bar_field',
        child: Material(
          color: colors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            enableFeedback: false,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? colors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 15,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: colors.onSurface, size: 19),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: BlocBuilder<HomeCubit, HomeState>(
                      buildWhen: (previous, current) =>
                          previous.nearbyPlaceNames !=
                              current.nearbyPlaceNames ||
                          previous.recentLocations != current.recentLocations,
                      builder: (context, state) {
                        final suggestions = state.nearbyPlaceNames.isNotEmpty
                            ? state.nearbyPlaceNames
                            : state.recentLocations.isEmpty
                            ? const <String>[]
                            : [
                                for (final location in state.recentLocations)
                                  location.title,
                              ];
                        return HomeDestinationSearchHint(
                          suggestions: suggestions,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.arrow_right,
                    color: colors.onSurfaceVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSavedPlacesSection extends StatelessWidget {
  const HomeSavedPlacesSection({
    super.key,
    required this.isAuthenticated,
    required this.onPlaceTap,
    required this.onPlaceLongPress,
    required this.onAddPlace,
  });

  final bool isAuthenticated;
  final ValueChanged<SavedPlace> onPlaceTap;
  final void Function(int index, SavedPlace place) onPlaceLongPress;
  final VoidCallback onAddPlace;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.places != current.places,
      builder: (context, state) {
        if (isAuthenticated && state.isLoading && state.places.isNotEmpty) {
          final placeholderCount = state.places.length + 1;
          return Skeletonizer.zone(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var index = 0; index < placeholderCount; index++)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Bone.button(
                        width: 90,
                        height: 38,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return SavedPlaceQuickActions(
          places: isAuthenticated ? state.places : const [],
          onPlaceTap: onPlaceTap,
          onPlaceLongPress: (place) {
            final index = state.places.indexOf(place);
            if (index >= 0) {
              onPlaceLongPress(index, place);
            }
          },
          onAddPlace: onAddPlace,
        );
      },
    );
  }
}

class HomeRecentActivitySection extends StatelessWidget {
  const HomeRecentActivitySection({
    super.key,
    required this.isAuthenticated,
    required this.onRideTap,
    required this.onRetry,
    this.previewLimit = 5,
  });

  final bool isAuthenticated;
  final ValueChanged<RideHistory> onRideTap;
  final VoidCallback onRetry;
  final int previewLimit;

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return const RecentRideHistoryEmptyState(isGuest: true);
    }

    return BlocBuilder<RideHistoryBloc, RideHistoryState>(
      builder: (context, state) {
        if (state is RideHistoryLoading && state.hasExistingRides) {
          final itemCount = state.existingRideCount
              .clamp(1, previewLimit)
              .toInt();
          return Skeletonizer.zone(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 54,
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              itemBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Bone.circle(size: 40),
                    SizedBox(width: 14),
                    Expanded(child: Bone.multiText(lines: 2, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is RideHistoryError) {
          return _buildError(context, state);
        }
        if (state is! RideHistoryLoaded) {
          return const RecentRideHistoryEmptyState(isGuest: false);
        }
        final recentRides = _deduplicateRecentRides(state.past);
        if (recentRides.isEmpty) {
          return const RecentRideHistoryEmptyState(isGuest: false);
        }
        return RecentRideHistoryPreview(
          rides: recentRides,
          onRideTap: onRideTap,
        );
      },
    );
  }

  List<RideHistory> _deduplicateRecentRides(List<RideHistory> past) {
    final seenDestinations = <String>{};
    final recentRides = <RideHistory>[];
    for (final ride in past) {
      final destinationKey = ride.destination.trim().toLowerCase();
      if (destinationKey.isEmpty || seenDestinations.add(destinationKey)) {
        recentRides.add(ride);
      }
      if (recentRides.length >= previewLimit) {
        break;
      }
    }
    return recentRides;
  }

  Widget _buildError(BuildContext context, RideHistoryError state) {
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return const SizedBox.shrink();
    }
    final title = switch (state.failureKind) {
      RideHistoryFailureKind.connection => 'Connection error',
      RideHistoryFailureKind.server => 'Server error',
      RideHistoryFailureKind.other => 'Could not load recent activity',
    };
    return AppRetryErrorView(
      title: title,
      message: state.message,
      actionLabel: 'Retry activity',
      icon: state.failureKind == RideHistoryFailureKind.connection
          ? LucideIcons.wifi_off
          : LucideIcons.circle_alert,
      onRetry: onRetry,
    );
  }
}

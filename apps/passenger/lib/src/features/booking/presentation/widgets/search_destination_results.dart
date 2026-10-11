import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/search_destination_formatters.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const SearchDestinationResults({
  super.key,
  required this.places,
  required this.hasQuery,
  required this.isLoading,
  required this.isLoadingMoreNearby,
  required this.bottomPadding,
  required this.scrollController,
  required this.drivingDistances,
  required this.drivingDistanceRequests,
  required this.onPlaceSelected,
}) extends StatelessWidget {
  final List<Place> places;
  final bool hasQuery;
  final bool isLoading;
  final bool isLoadingMoreNearby;
  final double bottomPadding;
  final ScrollController scrollController;
  final Map<String, double> drivingDistances;
  final Set<String> drivingDistanceRequests;
  final ValueChanged<Place> onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingList(context);
    if (places.isEmpty) {
      return Center(
        child: Text(
          hasQuery ? 'No places found' : 'No nearby places found',
          style: TextStyle(
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding + 16),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: places.length + (!hasQuery && isLoadingMoreNearby ? 1 : 0),
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: context.colorScheme.outlineVariant),
      itemBuilder: (context, index) {
        if (index == places.length) return _buildLoadingMoreRow(context);

        final place = places[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _determinePlaceIcon(place.name),
                color: context.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
          title: Text(
            place.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: context.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            formatDestinationPlaceDistance(
              place,
              drivingDistances,
              drivingDistanceRequests,
            ),
            style: TextStyle(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          trailing: Icon(
            LucideIcons.map_pin,
            size: 18,
            color: context.colorScheme.onSurface,
          ),
          onTap: () => onPlaceSelected(place),
        );
      },
    );
  }

  Widget _buildLoadingList(BuildContext context) {
    final hasPreviousResults = places.isNotEmpty;
    final bottomPaddingForLoading = hasPreviousResults
        ? bottomPadding
        : MediaQuery.paddingOf(context).bottom;

    return Skeletonizer.zone(
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPaddingForLoading + 16),
        physics: hasPreviousResults
            ? const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              )
            : null,
        itemCount: 8,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: context.colorScheme.outlineVariant),
        itemBuilder: (_, _) => const ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Bone.circle(size: 44),
          title: Bone.text(width: 130, fontSize: 15),
          subtitle: Bone.text(width: 90, fontSize: 13),
          trailing: Bone.icon(size: 18),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                  strokeWidth: 2,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Loading more nearby places...',
              style: TextStyle(
                color: context.colorScheme.outlineVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
}

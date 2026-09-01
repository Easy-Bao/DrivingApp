import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_controls_widget.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_header_widget.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_presenter.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_ride_card_widget.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

class const RideHistoryWidget({
  required this.activeRides,
  required this.pastRides,
  required this.referenceTime,
  required this.onRideTap,
  this.hasMore = false,
  this.isLoadingMore = false,
  this.loadMoreError,
  this.onLoadMore,
  this.weeklyFare,
  this.weeklyRideCount,
  super.key,
}) extends StatefulWidget {
  final List<RideHistory> activeRides;
  final List<RideHistory> pastRides;
  final DateTime referenceTime;
  final ValueChanged<RideHistory> onRideTap;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;
  final VoidCallback? onLoadMore;
  final double? weeklyFare;
  final int? weeklyRideCount;

  @override
  State<RideHistoryWidget> createState() => _RideHistoryWidgetState();
}

class _RideHistoryWidgetState extends State<RideHistoryWidget> {
  RideHistoryFilter _selectedFilter = RideHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final presenter = RideHistoryPresenter(widget.referenceTime);
    final sortedPastRides = presenter.sortPastRides(widget.pastRides);
    final filteredRides = _filterRides(sortedPastRides);
    final groupedRides = presenter.groupRides(filteredRides);
    final fallbackWeeklyRides = presenter.completedRidesThisWeek(
      sortedPastRides,
    );
    final fallbackWeeklyFare = fallbackWeeklyRides.fold<double>(
      0,
      (total, ride) => total + presenter.priceValue(ride.price),
    );

    return CustomScrollView(
      key: const ValueKey<String>('passenger-activity-history'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeaderWidget(
              subtitle: 'Tap a ride to see details',
            ),
          ),
        ),
        if (widget.activeRides.isNotEmpty) ..._activeRideSlivers(presenter),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: RideHistorySummaryWidget(
              weeklyFare: widget.weeklyFare ?? fallbackWeeklyFare,
              weeklyRideCount:
                  widget.weeklyRideCount ?? fallbackWeeklyRides.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          sliver: SliverToBoxAdapter(
            child: RideHistoryFiltersWidget(
              selectedFilter: _selectedFilter,
              onSelected: _selectFilter,
            ),
          ),
        ),
        if (filteredRides.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: RideHistoryFilteredEmptyWidget(filter: _selectedFilter),
          )
        else
          ..._historySlivers(groupedRides, presenter),
        if (filteredRides.isNotEmpty &&
            (widget.hasMore || widget.loadMoreError != null))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildLoadMore()),
          ),
        if (filteredRides.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }

  Widget _buildLoadMore() {
    if (widget.isLoadingMore) {
      return Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colorScheme.onSurface,
          ),
        ),
      );
    }
    return Column(
      children: [
        if (widget.loadMoreError != null) ...[
          Text(
            widget.loadMoreError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextButton.icon(
          onPressed: widget.onLoadMore,
          style: TextButton.styleFrom(
            foregroundColor: context.colorScheme.onSurface,
          ),
          icon: const Icon(LucideIcons.chevron_down, size: 16),
          label: Text(
            widget.loadMoreError == null ? 'Load more rides' : 'Retry',
          ),
        ),
      ],
    );
  }

  void _selectFilter(RideHistoryFilter filter) {
    if (filter == _selectedFilter) return;
    setState(() => _selectedFilter = filter);
  }

  List<RideHistory> _filterRides(List<RideHistory> rides) {
    return switch (_selectedFilter) {
      RideHistoryFilter.all => rides,
      RideHistoryFilter.completed =>
        rides
            .where(
              (ride) =>
                  RideStatus.fromString(ride.status) == RideStatus.completed,
            )
            .toList(),
      RideHistoryFilter.cancelled =>
        rides
            .where(
              (ride) =>
                  RideStatus.fromString(ride.status) == RideStatus.cancelled,
            )
            .toList(),
    };
  }

  List<Widget> _activeRideSlivers(RideHistoryPresenter presenter) {
    return [
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
        sliver: SliverToBoxAdapter(
          child: RideHistorySectionLabel(label: 'Active ride'),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.builder(
          itemCount: widget.activeRides.length,
          itemBuilder: (context, index) {
            final ride = widget.activeRides[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PassengerActiveRideCardWidget(
                ride: ride,
                presenter: presenter,
                onTap: () => widget.onRideTap(ride),
              ),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
    ];
  }

  List<Widget> _historySlivers(
    Map<String, List<RideHistory>> groupedRides,
    RideHistoryPresenter presenter,
  ) {
    final slivers = <Widget>[];
    for (final entry in groupedRides.entries) {
      slivers
        ..add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            sliver: SliverToBoxAdapter(
              child: RideHistorySectionLabel(label: entry.key),
            ),
          ),
        )
        ..add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final ride = entry.value[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PassengerPastRideCardWidget(
                    ride: ride,
                    presenter: presenter,
                    onTap: () => widget.onRideTap(ride),
                  ),
                );
              },
            ),
          ),
        );
    }
    return slivers;
  }
}

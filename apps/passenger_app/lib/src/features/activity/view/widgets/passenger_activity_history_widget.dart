import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/view/widgets/passenger_activity_controls_widget.dart';
import 'package:passenger_app/src/features/activity/view/widgets/passenger_activity_header_widget.dart';
import 'package:passenger_app/src/features/activity/view/widgets/passenger_activity_history_presenter.dart';
import 'package:passenger_app/src/features/activity/view/widgets/passenger_activity_ride_card_widget.dart';
import 'package:shared_core/shared_core.dart';

class PassengerActivityHistoryWidget extends StatefulWidget {
  final List<RideHistoryModel> activeRides;
  final List<RideHistoryModel> pastRides;
  final DateTime referenceTime;
  final ValueChanged<RideHistoryModel> onRideTap;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;
  final VoidCallback? onLoadMore;
  final double? weeklyFare;
  final int? weeklyRideCount;

  const PassengerActivityHistoryWidget({
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
  });

  @override
  State<PassengerActivityHistoryWidget> createState() =>
      _PassengerActivityHistoryWidgetState();
}

class _PassengerActivityHistoryWidgetState
    extends State<PassengerActivityHistoryWidget> {
  PassengerActivityFilter _selectedFilter = PassengerActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final presenter = PassengerActivityHistoryPresenter(widget.referenceTime);
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
            child: PassengerActivityHeaderWidget(
              subtitle: 'Tap a ride to see details',
            ),
          ),
        ),
        if (widget.activeRides.isNotEmpty) ..._activeRideSlivers(presenter),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: PassengerActivitySummaryWidget(
              weeklyFare: widget.weeklyFare ?? fallbackWeeklyFare,
              weeklyRideCount:
                  widget.weeklyRideCount ?? fallbackWeeklyRides.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          sliver: SliverToBoxAdapter(
            child: PassengerActivityFiltersWidget(
              selectedFilter: _selectedFilter,
              onSelected: _selectFilter,
            ),
          ),
        ),
        if (filteredRides.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: PassengerActivityFilteredEmptyWidget(
              filter: _selectedFilter,
            ),
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
      return const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
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
            style: const TextStyle(
              color: AppTheme.cancel,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextButton.icon(
          onPressed: widget.onLoadMore,
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          icon: const Icon(LucideIcons.chevron_down, size: 16),
          label: Text(
            widget.loadMoreError == null ? 'Load more rides' : 'Retry',
          ),
        ),
      ],
    );
  }

  void _selectFilter(PassengerActivityFilter filter) {
    if (filter == _selectedFilter) return;
    setState(() => _selectedFilter = filter);
  }

  List<RideHistoryModel> _filterRides(List<RideHistoryModel> rides) {
    return switch (_selectedFilter) {
      PassengerActivityFilter.all => rides,
      PassengerActivityFilter.completed =>
        rides
            .where(
              (ride) =>
                  RideStatus.fromString(ride.status) == RideStatus.completed,
            )
            .toList(),
      PassengerActivityFilter.cancelled =>
        rides
            .where(
              (ride) =>
                  RideStatus.fromString(ride.status) == RideStatus.cancelled,
            )
            .toList(),
    };
  }

  List<Widget> _activeRideSlivers(PassengerActivityHistoryPresenter presenter) {
    return [
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
        sliver: SliverToBoxAdapter(
          child: PassengerActivitySectionLabel(label: 'Active ride'),
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
    Map<String, List<RideHistoryModel>> groupedRides,
    PassengerActivityHistoryPresenter presenter,
  ) {
    final slivers = <Widget>[];
    for (final entry in groupedRides.entries) {
      slivers
        ..add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            sliver: SliverToBoxAdapter(
              child: PassengerActivitySectionLabel(label: entry.key),
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

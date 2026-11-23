import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/ride_history/presentation/formatters/ride_history_presenter.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_card.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_controls.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_header.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

class RideHistoryListView extends StatefulWidget {
  const RideHistoryListView({
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
    this.headerTitle = 'Activity',
    this.headerSubtitle = 'Your trips and receipts',
    this.showBackButton = false,
    this.showHeaderSubtitle = true,
    this.showSummary = true,
    this.showFilters = true,
    super.key,
  });
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
  final String headerTitle;
  final String headerSubtitle;
  final bool showBackButton;
  final bool showHeaderSubtitle;
  final bool showSummary;
  final bool showFilters;

  @override
  State<RideHistoryListView> createState() => _RideHistoryListViewState();
}

class _RideHistoryListViewState extends State<RideHistoryListView> {
  RideHistoryFilter _selectedFilter = RideHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? AppLayout.pagePadding
        : AppLayout.pagePaddingWide;
    final presenter = RideHistoryPresenter(
      widget.referenceTime,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
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
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeader(
              title: widget.headerTitle,
              subtitle: widget.showHeaderSubtitle
                  ? widget.headerSubtitle
                  : null,
              showBackButton: widget.showBackButton,
            ),
          ),
        ),
        if (widget.activeRides.isNotEmpty)
          ..._activeRideSlivers(presenter, horizontalPadding),
        if (widget.showSummary)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverToBoxAdapter(
              child: RideHistorySummary(
                weeklyFare: widget.weeklyFare ?? fallbackWeeklyFare,
                weeklyRideCount:
                    widget.weeklyRideCount ?? fallbackWeeklyRides.length,
              ),
            ),
          ),
        if (widget.showFilters)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.md,
              horizontalPadding,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: RideHistoryFilters(
                selectedFilter: _selectedFilter,
                onSelected: _selectFilter,
              ),
            ),
          ),
        if (filteredRides.isEmpty)
          if (widget.activeRides.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 64),
                child: RideHistoryFilteredEmpty(filter: _selectedFilter),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: RideHistoryFilteredEmpty(filter: _selectedFilter),
            )
        else
          ..._historySlivers(groupedRides, presenter, horizontalPadding),
        if (filteredRides.isNotEmpty &&
            (widget.hasMore ||
                (widget.loadMoreError != null &&
                    !AppNetworkStatusScope.isUnavailableOf(context))))
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.md,
              horizontalPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _buildLoadMore()),
          ),
        if (filteredRides.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }

  Widget _buildLoadMore() {
    final colors = context.colorScheme;
    if (widget.isLoadingMore) {
      return Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.onSurface,
          ),
        ),
      );
    }
    return Column(
      children: [
        if (widget.loadMoreError != null &&
            !AppNetworkStatusScope.isUnavailableOf(context)) ...[
          Text(
            widget.loadMoreError!,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextButton.icon(
          onPressed: widget.onLoadMore,
          style:
              TextButton.styleFrom(
                foregroundColor: colors.onSurface,
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size(0, AppSize.minimumTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? colors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
              ),
          icon: const Icon(LucideIcons.chevron_down, size: 16),
          label: Text(
            widget.loadMoreError == null ||
                    AppNetworkStatusScope.isUnavailableOf(context)
                ? 'Load more rides'
                : 'Retry',
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

  List<Widget> _activeRideSlivers(
    RideHistoryPresenter presenter,
    double horizontalPadding,
  ) {
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          AppSpacing.sm,
        ),
        sliver: const SliverToBoxAdapter(
          child: RideHistorySectionLabel(label: 'Active ride'),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        sliver: SliverList.builder(
          itemCount: widget.activeRides.length,
          itemBuilder: (context, index) {
            final ride = widget.activeRides[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ActiveRideCard(
                ride: ride,
                presenter: presenter,
                onTap: () => widget.onRideTap(ride),
              ),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
    ];
  }

  List<Widget> _historySlivers(
    Map<String, List<RideHistory>> groupedRides,
    RideHistoryPresenter presenter,
    double horizontalPadding,
  ) {
    final slivers = <Widget>[];
    final entries = groupedRides.entries.toList();
    for (var groupIndex = 0; groupIndex < entries.length; groupIndex++) {
      final entry = entries[groupIndex];
      slivers
        ..add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              groupIndex == 0 ? 0 : AppSpacing.lg,
              horizontalPadding,
              AppSpacing.xs,
            ),
            sliver: SliverToBoxAdapter(
              child: RideHistorySectionLabel(label: entry.key),
            ),
          ),
        )
        ..add(
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverList.builder(
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final ride = entry.value[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        indent: 54,
                        color: context.colorScheme.outlineVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    PastRideCard(
                      ride: ride,
                      presenter: presenter,
                      onTap: () => widget.onRideTap(ride),
                    ),
                  ],
                );
              },
            ),
          ),
        );
    }
    return slivers;
  }
}

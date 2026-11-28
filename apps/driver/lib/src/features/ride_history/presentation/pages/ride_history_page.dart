import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/ride_history_cubit.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/ride_history_state.dart';
import 'package:driver/src/features/ride_history/presentation/formatters/trip_history_grouper.dart';
import 'package:driver/src/features/ride_history/presentation/widgets/ride_history_filter_bar.dart';
import 'package:driver/src/features/ride_history/presentation/widgets/ride_history_trip_row.dart';
import 'package:driver/src/features/ride_history/ride_history_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

class const TripHistoryPage({super.key}) extends StatefulWidget {
  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 220);

  late final AnimationController _filterTransitionController;
  late final CurvedAnimation _filterTransitionCurve;
  DriverTripHistoryFilter _selectedFilter = DriverTripHistoryFilter.all;
  double _slideDirection = 0;

  List<Map<String, dynamic>>? _cachedTrips;
  DriverTripHistoryFilter? _cachedFilter;
  DriverTripHistoryGroups? _cachedGroups;

  @override
  void initState() {
    super.initState();
    _filterTransitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1,
    );
    _filterTransitionCurve = CurvedAnimation(
      parent: _filterTransitionController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _filterTransitionCurve.dispose();
    _filterTransitionController.dispose();
    super.dispose();
  }

  void _selectFilter(DriverTripHistoryFilter next) {
    if (next == _selectedFilter) return;
    setState(() {
      _slideDirection = next.index > _selectedFilter.index ? 1.0 : -1.0;
      _selectedFilter = next;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _filterTransitionController.value = 1;
    } else {
      unawaited(_filterTransitionController.forward(from: 0));
    }
  }

  DriverTripHistoryGroups _groupsFor(List<Map<String, dynamic>> trips) {
    final cached = _cachedGroups;
    if (cached != null &&
        identical(trips, _cachedTrips) &&
        _cachedFilter == _selectedFilter) {
      return cached;
    }
    final computed = groupDriverTrips(trips, _selectedFilter);
    _cachedTrips = trips;
    _cachedFilter = _selectedFilter;
    _cachedGroups = computed;
    return computed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.pageMaxWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? AppLayout.pagePadding
                    : AppLayout.pagePaddingWide;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.sm,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppPageHeader(title: 'Trip History'),
                          const SizedBox(height: AppSpacing.md),
                          TripHistoryFilterBar(
                            selectedFilter: _selectedFilter,
                            onSelected: _selectFilter,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<TripHistoryCubit, TripHistoryState>(
                        builder: (context, state) => _buildBody(
                          context,
                          state,
                          horizontalPadding: horizontalPadding,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TripHistoryState state, {
    required double horizontalPadding,
  }) {
    final hasTrips = state.trips.isNotEmpty;
    final isNetworkUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    final errorMessage = state.errorMessage;
    if (state.isLoading && !hasTrips) {
      return TripHistoryLoadingSkeleton(horizontalPadding: horizontalPadding);
    }
    if (errorMessage != null && !hasTrips && !isNetworkUnavailable) {
      return TripHistoryMessageState(
        horizontalPadding: horizontalPadding,
        title: 'Couldn’t load trips',
        message: errorMessage,
        icon: LucideIcons.circle_alert,
        actionLabel: 'Try again',
        onAction: () => BlocProvider.of<TripHistoryCubit>(context).load(),
        onRefresh: () => BlocProvider.of<TripHistoryCubit>(context).load(),
      );
    }

    final grouped = _groupsFor(state.trips);
    final hasRefreshError =
        errorMessage != null && hasTrips && !isNetworkUnavailable;
    final hasLoadMoreItem =
        state.hasMore ||
        state.isLoadingMore ||
        (state.loadMoreError != null && !isNetworkUnavailable);

    return AnimatedBuilder(
      animation: _filterTransitionCurve,
      builder: (context, child) {
        final progress = _filterTransitionCurve.value;
        final dx = _slideDirection * 12 * (1 - progress);
        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
      child: grouped.filteredTrips.isEmpty
          ? TripHistoryMessageState(
              horizontalPadding: horizontalPadding,
              title: hasTrips ? 'No trips match this filter' : 'No trips yet',
              message: hasTrips
                  ? 'Try another status or clear the filter.'
                  : 'Completed and canceled trips will appear here.',
              icon: hasTrips ? LucideIcons.funnel : LucideIcons.history,
              actionLabel: hasTrips ? 'Clear filter' : null,
              onAction: hasTrips
                  ? () => _selectFilter(DriverTripHistoryFilter.all)
                  : null,
              onRefresh: () =>
                  BlocProvider.of<TripHistoryCubit>(context).load(),
            )
          : RefreshIndicator(
              color: context.colorScheme.onSurface,
              onRefresh: () =>
                  BlocProvider.of<TripHistoryCubit>(context).load(),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.sm,
                  horizontalPadding,
                  AppSpacing.xxxl,
                ),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                itemCount:
                    grouped.entries.length +
                    (hasRefreshError ? 1 : 0) +
                    (hasLoadMoreItem ? 1 : 0),
                itemBuilder: (context, groupIndex) {
                  if (hasRefreshError && groupIndex == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.xs,
                      ),
                      child: AppErrorBanner(
                        message: errorMessage,
                        onRetry: () =>
                            BlocProvider.of<TripHistoryCubit>(context).load(),
                        onDismiss: () =>
                            BlocProvider.of<TripHistoryCubit>(context)
                                .dismissError(),
                      ),
                    );
                  }
                  final contentIndex = groupIndex - (hasRefreshError ? 1 : 0);
                  if (hasLoadMoreItem &&
                      contentIndex == grouped.entries.length) {
                    return TripHistoryLoadMoreFooter(
                      state: state,
                      onLoadMore: () =>
                          BlocProvider.of<TripHistoryCubit>(context).loadMore(),
                    );
                  }
                  final entry = grouped.entries[contentIndex];
                  final trips = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xl,
                          bottom: AppSpacing.sm,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            entry.key.toUpperCase(),
                            style: context.textStyles.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                      ),
                      for (var index = 0; index < trips.length; index++) ...[
                        TripHistoryRow(
                          trip: trips[index],
                          onTap: () => context.pushNamed(
                            RideHistoryRoutes.tripDetail,
                            extra: trips[index],
                          ),
                        ),
                        if (index != trips.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: context.colorScheme.outlineVariant
                                .withValues(alpha: 0.7),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ),
    );
  }
}

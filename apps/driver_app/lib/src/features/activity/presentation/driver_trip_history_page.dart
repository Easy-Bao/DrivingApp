import 'dart:async';

import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:driver_app/src/features/activity/activity_routes.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/trip_history/trip_history_cubit.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/trip_history/trip_history_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:design_system/design_system.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DriverTripHistoryPage extends StatefulWidget {
  const DriverTripHistoryPage({super.key});

  @override
  State<DriverTripHistoryPage> createState() => _DriverTripHistoryPageState();
}

class _DriverTripHistoryPageState extends State<DriverTripHistoryPage> {
  String _selectedTripStatusFilter = 'ALL';

  List<Map<String, dynamic>> _filteredTripsList(
    List<Map<String, dynamic>> trips,
  ) {
    if (_selectedTripStatusFilter == 'ALL') {
      return trips;
    }
    return trips.where((tripRecord) {
      final statusString = (tripRecord['status'] as String? ?? '')
          .toUpperCase();
      return statusString == _selectedTripStatusFilter;
    }).toList();
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tripDate = DateTime(dt.year, dt.month, dt.day);

      if (tripDate == today) {
        return 'Today';
      } else if (tripDate == yesterday) {
        return 'Yesterday';
      } else {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    } catch (_) {
      return 'Past Trip';
    }
  }

  Future<void> _displayDriverTripHistoryFilterModalBottomSheet(
    BuildContext context,
  ) async {
    final selectedFilter = switch (_selectedTripStatusFilter) {
      'COMPLETED' => TripHistoryFilter.completed,
      'CANCELLED' => TripHistoryFilter.cancelled,
      _ => TripHistoryFilter.all,
    };
    final result = await showTripHistoryFilterSheet(
      context: context,
      selectedFilter: selectedFilter,
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedTripStatusFilter = switch (result) {
        TripHistoryFilter.all => 'ALL',
        TripHistoryFilter.completed => 'COMPLETED',
        TripHistoryFilter.cancelled => 'CANCELLED',
      };
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> trips,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final t in trips) {
      final dateStr = _formatDate(
        driverValueAsString(t['completed_at']) ??
            driverValueAsString(t['created_at']) ??
            '',
      );
      map.putIfAbsent(dateStr, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DriverTripHistoryCubit>().state;
    final filteredTrips = _filteredTripsList(state.trips);
    final grouped = _groupByDate(filteredTrips);
    final hasTrips = state.trips.isNotEmpty;
    final hasRefreshError = state.errorMessage != null && hasTrips;
    final hasLoadMoreItem =
        state.hasMore || state.isLoadingMore || state.loadMoreError != null;

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        backgroundColor: context.canvasColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Trip History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.funnel,
              color: context.colorScheme.onSurface,
            ),
            onPressed: () => unawaited(
              _displayDriverTripHistoryFilterModalBottomSheet(context),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.trips.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: context.colorScheme.onSurface,
              ),
            )
          : state.errorMessage != null && !hasTrips
          ? _buildMessageState(
              title: 'Couldn’t load trips',
              message: state.errorMessage!,
              icon: LucideIcons.wifi_off,
              actionLabel: 'Try again',
              onAction: () =>
                  BlocProvider.of<DriverTripHistoryCubit>(context).load(),
            )
          : filteredTrips.isEmpty
          ? _buildMessageState(
              title: hasTrips ? 'No trips match this filter' : 'No trips yet',
              message: hasTrips
                  ? 'Try another status or clear the filter.'
                  : 'Completed and canceled trips will appear here.',
              icon: hasTrips ? LucideIcons.funnel : LucideIcons.history,
              actionLabel: hasTrips ? 'Clear filter' : null,
              onAction: hasTrips
                  ? () => setState(() => _selectedTripStatusFilter = 'ALL')
                  : null,
            )
          : RefreshIndicator(
              color: context.colorScheme.onSurface,
              onRefresh: () =>
                  BlocProvider.of<DriverTripHistoryCubit>(context).load(),
              child: Skeletonizer(
                enabled: state.isLoading,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount:
                      grouped.keys.length +
                      (hasRefreshError ? 1 : 0) +
                      (hasLoadMoreItem ? 1 : 0),
                  itemBuilder: (context, groupIndex) {
                    if (hasRefreshError && groupIndex == 0) {
                      return _buildRefreshError(state.errorMessage!);
                    }
                    final contentIndex = groupIndex - (hasRefreshError ? 1 : 0);
                    if (hasLoadMoreItem &&
                        contentIndex == grouped.keys.length) {
                      return _buildLoadMore(state);
                    }
                    final date = grouped.keys.elementAt(contentIndex);
                    final trips = grouped[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 12),
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: context.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...trips.map(_buildTripCard),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildMessageState({
    required String title,
    required String message,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return RefreshIndicator(
      color: context.colorScheme.onSurface,
      onRefresh: () => BlocProvider.of<DriverTripHistoryCubit>(context).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(28, 120, 28, 120),
        children: [
          Icon(
            icon,
            size: 56,
            color: context.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.onSurface,
              ),
              icon: const Icon(LucideIcons.refresh_cw, size: 16),
              label: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        decoration: BoxDecoration(
          color: context.colorScheme.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.wifi_off,
                  size: 17,
                  color: context.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Couldn’t refresh trips',
                  style: TextStyle(
                    color: context.colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    BlocProvider.of<DriverTripHistoryCubit>(context).load(),
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.onSurface,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(LucideIcons.refresh_cw, size: 15),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMore(DriverTripHistoryState state) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Column(
        children: [
          if (state.loadMoreError != null) ...[
            Text(
              state.loadMoreError!,
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
            onPressed: () =>
                BlocProvider.of<DriverTripHistoryCubit>(context).loadMore(),
            icon: const Icon(LucideIcons.chevron_down, size: 16),
            label: Text(
              state.loadMoreError == null ? 'Load more trips' : 'Retry',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = (driverValueAsString(trip['status']) ?? 'completed')
        .toLowerCase();
    final isCompleted = status == 'completed';
    final statusColor = isCompleted
        ? context.semanticColors.success
        : context.colorScheme.error;
    final statusLabel = isCompleted
        ? 'Completed'
        : driverSentenceCase(status, 'Canceled');
    final fromName = driverValueAsString(trip['pickup_name']) ?? 'Pickup';
    final toName = driverValueAsString(trip['dropoff_name']) ?? 'Drop-off';
    final fareAmt = driverFareInPesos(trip);
    final rideType = driverSentenceCase(trip['ride_type'], 'Solo ride');
    final distance =
        trip['distance_km'] is num &&
            (trip['distance_km'] as num).isFinite &&
            (trip['distance_km'] as num) > 0
        ? DistanceFormatter.fromKilometers(trip['distance_km'] as num)
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              context.pushNamed(ActivityRoutes.tripDetail, extra: trip),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTripTime(trip),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CompactRouteTimelineWidget(pickup: fromName, dropoff: toName),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _tripMeta('Ride type', rideType)),
                    Container(
                      width: 1,
                      height: 28,
                      color: context.colorScheme.outlineVariant,
                    ),
                    Expanded(child: _tripMeta('Distance', distance)),
                    Container(
                      width: 1,
                      height: 28,
                      color: context.colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: _tripMeta(
                        'Fare',
                        fareAmt == null ? '—' : formatPesoAmount(fareAmt),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTripTime(dynamic trip) {
    final rawDate =
        driverValueAsString(trip['completed_at']) ??
        driverValueAsString(trip['created_at']);
    if (rawDate == null) return 'Past trip';
    try {
      final date = DateTime.parse(rawDate).toLocal();
      final hour = date.hour == 0
          ? 12
          : date.hour > 12
          ? date.hour - 12
          : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return 'Past trip';
    }
  }

  Widget _tripMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

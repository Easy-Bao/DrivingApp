import 'dart:async';

import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:driver_app/src/features/activity/activity_routes.dart';
import 'package:driver_app/src/features/activity/bloc/trip_history/trip_history_cubit.dart';
import 'package:driver_app/src/features/activity/bloc/trip_history/trip_history_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Trip History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.funnel, color: AppTheme.primaryColor),
            onPressed: () => unawaited(
              _displayDriverTripHistoryFilterModalBottomSheet(context),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.trips.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : filteredTrips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.history,
                    size: 64,
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trip history found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primaryColor,
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
                      ((state.hasMore ||
                              state.isLoadingMore ||
                              state.loadMoreError != null)
                          ? 1
                          : 0),
                  itemBuilder: (context, groupIndex) {
                    if (groupIndex == grouped.keys.length) {
                      return _buildLoadMore(state);
                    }
                    final date = grouped.keys.elementAt(groupIndex);
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
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
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

  Widget _buildLoadMore(DriverTripHistoryState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
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
              style: const TextStyle(
                color: AppTheme.cancel,
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
    final statusColor = isCompleted ? AppTheme.complete : AppTheme.cancel;
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              context.pushNamed(ActivityRoutes.tripDetail, extra: trip),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSide),
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
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
                    Container(width: 1, height: 28, color: AppTheme.borderSide),
                    Expanded(child: _tripMeta('Distance', distance)),
                    Container(width: 1, height: 28, color: AppTheme.borderSide),
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

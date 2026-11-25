import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_state.dart';
import 'package:driver/src/features/ride_history/presentation/widgets/trip_history_filter_bar.dart';
import 'package:driver/src/features/ride_history/ride_history_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const TripHistoryPage({super.key}) extends StatefulWidget {
  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 220);

  late final AnimationController _filterTransitionController;
  late final Animation<double> _filterTransitionCurve;
  DriverTripHistoryFilter _selectedFilter = DriverTripHistoryFilter.all;
  double _slideDirection = 0;

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

  List<Map<String, dynamic>> _filteredTripsList(
    List<Map<String, dynamic>> trips,
  ) {
    return switch (_selectedFilter) {
      DriverTripHistoryFilter.all => trips,
      DriverTripHistoryFilter.completed =>
        trips
            .where(
              (trip) =>
                  (valueAsString(trip['status']) ?? '').toUpperCase() ==
                  'COMPLETED',
            )
            .toList(growable: false),
      DriverTripHistoryFilter.cancelled =>
        trips
            .where((trip) {
              final status = (valueAsString(trip['status']) ?? '')
                  .toUpperCase();
              return status == 'CANCELLED' || status == 'CANCELED';
            })
            .toList(growable: false),
    };
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tripDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

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
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
      }
    } catch (_) {
      return 'Past Trip';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> trips,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final trip in trips) {
      final formattedDate = _formatDate(
        valueAsString(trip['completed_at']) ??
            valueAsString(trip['created_at']) ??
            '',
      );
      map.putIfAbsent(formattedDate, () => []).add(trip);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TripHistoryCubit>().state;
    final filteredTrips = _filteredTripsList(state.trips);
    final grouped = _groupByDate(filteredTrips);
    final hasTrips = state.trips.isNotEmpty;
    final isNetworkUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    final hasRefreshError =
        state.errorMessage != null && hasTrips && !isNetworkUnavailable;
    final hasLoadMoreItem =
        state.hasMore ||
        state.isLoadingMore ||
        (state.loadMoreError != null && !isNetworkUnavailable);

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
                      child: state.isLoading && state.trips.isEmpty
                          ? _buildInitialLoadingState(horizontalPadding)
                          : state.errorMessage != null &&
                                !hasTrips &&
                                !isNetworkUnavailable
                          ? _buildMessageState(
                              horizontalPadding: horizontalPadding,
                              title: 'Couldn’t load trips',
                              message: state.errorMessage!,
                              icon: LucideIcons.circle_alert,
                              actionLabel: 'Try again',
                              onAction: () =>
                                  BlocProvider.of<TripHistoryCubit>(context)
                                      .load(),
                            )
                          : AnimatedBuilder(
                              animation: _filterTransitionCurve,
                              builder: (context, child) {
                                final progress = _filterTransitionCurve.value;
                                final dx =
                                    _slideDirection * 12 * (1 - progress);
                                return Opacity(
                                  opacity: progress.clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset(dx, 0),
                                    child: child,
                                  ),
                                );
                              },
                              child: filteredTrips.isEmpty
                                  ? _buildMessageState(
                                      horizontalPadding: horizontalPadding,
                                      title: hasTrips
                                          ? 'No trips match this filter'
                                          : 'No trips yet',
                                      message: hasTrips
                                          ? 'Try another status or clear the filter.'
                                          : 'Completed and canceled trips will appear here.',
                                      icon: hasTrips
                                          ? LucideIcons.funnel
                                          : LucideIcons.history,
                                      actionLabel: hasTrips
                                          ? 'Clear filter'
                                          : null,
                                      onAction: hasTrips
                                          ? () => _selectFilter(
                                              DriverTripHistoryFilter.all,
                                            )
                                          : null,
                                    )
                                  : RefreshIndicator(
                                      color: context.colorScheme.onSurface,
                                      onRefresh: () =>
                                          BlocProvider.of<TripHistoryCubit>(
                                            context,
                                          ).load(),
                                      child: ListView.builder(
                                        padding: EdgeInsets.fromLTRB(
                                          horizontalPadding,
                                          AppSpacing.sm,
                                          horizontalPadding,
                                          AppSpacing.xxxl,
                                        ),
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                              parent: ClampingScrollPhysics(),
                                            ),
                                        itemCount:
                                            grouped.keys.length +
                                            (hasRefreshError ? 1 : 0) +
                                            (hasLoadMoreItem ? 1 : 0),
                                        itemBuilder: (context, groupIndex) {
                                          if (hasRefreshError &&
                                              groupIndex == 0) {
                                            return _buildRefreshError(
                                              state.errorMessage!,
                                            );
                                          }
                                          final contentIndex =
                                              groupIndex -
                                              (hasRefreshError ? 1 : 0);
                                          if (hasLoadMoreItem &&
                                              contentIndex ==
                                                  grouped.keys.length) {
                                            return _buildLoadMore(state);
                                          }
                                          final date = grouped.keys.elementAt(
                                            contentIndex,
                                          );
                                          final trips = grouped[date]!;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: AppSpacing.xl,
                                                  bottom: AppSpacing.sm,
                                                ),
                                                child: Semantics(
                                                  header: true,
                                                  child: Text(
                                                    date.toUpperCase(),
                                                    style: context
                                                        .textStyles
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: context
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                          letterSpacing: 0.9,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              for (
                                                var index = 0;
                                                index < trips.length;
                                                index++
                                              ) ...[
                                                _buildTripRow(trips[index]),
                                                if (index != trips.length - 1)
                                                  Divider(
                                                    height: 1,
                                                    thickness: 1,
                                                    color: context
                                                        .colorScheme
                                                        .outlineVariant
                                                        .withValues(alpha: 0.7),
                                                  ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
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

  Widget _buildInitialLoadingState(double horizontalPadding) {
    final hairlineColor = context.colorScheme.outlineVariant.withValues(
      alpha: 0.7,
    );
    return Skeletonizer.zone(
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.xl,
          horizontalPadding,
          AppSpacing.xxxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        itemCount: 4,
        separatorBuilder: (_, _) =>
            Divider(height: 1, thickness: 1, color: hairlineColor),
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Bone.text(width: 68, fontSize: 12),
                  Bone.text(width: 72, fontSize: 12),
                ],
              ),
              SizedBox(height: 12),
              Bone.text(width: 190, fontSize: 14),
              SizedBox(height: 8),
              Bone.text(width: 150, fontSize: 14),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Bone.text(width: 56, fontSize: 12),
                  Bone.text(width: 64, fontSize: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required double horizontalPadding,
    required String title,
    required String message,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return RefreshIndicator(
      color: colorScheme.onSurface,
      onRefresh: () => BlocProvider.of<TripHistoryCubit>(context).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          84,
          horizontalPadding,
          84,
        ),
        children: [
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: textStyles.bodySmall?.copyWith(
                  height: 1.45,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: onAction,
                style:
                    TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return colorScheme.primary.withValues(alpha: 0.12);
                        }
                        return Colors.transparent;
                      }),
                    ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: AppErrorBanner(
        message: message,
        onRetry: () => BlocProvider.of<TripHistoryCubit>(context).load(),
      ),
    );
  }

  Widget _buildLoadMore(TripHistoryState state) {
    final colorScheme = context.colorScheme;
    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
      child: Column(
        children: [
          if (state.loadMoreError != null &&
              !AppNetworkStatusScope.isUnavailableOf(context)) ...[
            Text(
              state.loadMoreError!,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          TextButton.icon(
            onPressed: () =>
                BlocProvider.of<TripHistoryCubit>(context).loadMore(),
            style:
                TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return colorScheme.primary.withValues(alpha: 0.12);
                    }
                    return Colors.transparent;
                  }),
                ),
            icon: const Icon(LucideIcons.chevron_down, size: 16),
            label: Text(
              state.loadMoreError == null ||
                      AppNetworkStatusScope.isUnavailableOf(context)
                  ? 'Load more trips'
                  : 'Retry',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripRow(Map<String, dynamic> trip) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final status = (valueAsString(trip['status']) ?? 'completed').toLowerCase();
    final isCompleted = status == 'completed';
    final statusColor = isCompleted
        ? context.semanticColors.success
        : colorScheme.error;
    final statusLabel = isCompleted
        ? 'Completed'
        : sentenceCase(status, 'Canceled');
    final fromName = valueAsString(trip['pickup_name']) ?? 'Pickup';
    final toName = valueAsString(trip['dropoff_name']) ?? 'Drop-off';
    final formattedFareAmount = fareInPesos(trip);
    final fareText = formattedFareAmount == null
        ? '—'
        : formatPesoAmount(formattedFareAmount);
    final tripTime = _formatTripTime(
      trip,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    final distance =
        trip['distance_km'] is num &&
            (trip['distance_km'] as num).isFinite &&
            (trip['distance_km'] as num) > 0
        ? DistanceFormatter.fromKilometers(trip['distance_km'] as num)
        : '—';

    return InkWell(
      key: ValueKey<String>(
        'driver-trip-row-${valueAsString(trip['id']) ?? tripTime}',
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      enableFeedback: false,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        return Colors.transparent;
      }),
      onTap: () => context.pushNamed(RideHistoryRoutes.tripDetail, extra: trip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tripTime,
                    style: textStyles.labelMedium?.tabular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: textStyles.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (valueAsString(trip['booking_reference'])
                case final String reference when reference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              TripReference(id: reference, compact: true),
            ],
            const SizedBox(height: AppSpacing.md),
            CompactRouteTimeline(pickup: fromName, dropoff: toName),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    distance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyles.bodySmall?.tabular.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  fareText,
                  style: textStyles.titleSmall?.tabular.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ExcludeSemantics(
                  child: Icon(
                    LucideIcons.chevron_right,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTripTime(
    Map<String, dynamic> trip, {
    required bool alwaysUse24HourFormat,
  }) {
    final rawDate =
        valueAsString(trip['completed_at']) ??
        valueAsString(trip['created_at']);
    if (rawDate == null) return 'Past trip';
    try {
      final date = DateTime.parse(rawDate).toLocal();
      if (alwaysUse24HourFormat) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
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
}

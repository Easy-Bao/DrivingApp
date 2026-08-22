import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/activity/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PassengerActivityPage extends StatefulWidget {
  const PassengerActivityPage({super.key});

  @override
  State<PassengerActivityPage> createState() => _PassengerActivityPageState();
}

class _PassengerActivityPageState extends State<PassengerActivityPage> {
  static const int _activitySkeletonLimit = 5;

  bool _hasLoadedActivity = false;

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<SessionBloc, bool>((bloc) {
      final sessionState = bloc.state;
      return sessionState is GuestSession || sessionState is SessionFailure;
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _loadActivity,
          child: BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              if (isGuest) {
                return _buildGuestEmptyState();
              }
              if (state is ActivityLoading) {
                final itemCount = state.existingRideCount
                    .clamp(0, _activitySkeletonLimit)
                    .toInt();
                return itemCount > 0
                    ? _buildLoadingState(itemCount: itemCount)
                    : _buildEmptyActivityState();
              }
              if (state is ActivityError) {
                return _buildErrorState(state.message);
              }
              if (state is ActivityInitial) {
                return _buildEmptyActivityState();
              }
              if (state is ActivityLoaded) {
                final activeRides = state.upcoming;
                final pastRides = state.past;

                if (activeRides.isEmpty && pastRides.isEmpty) {
                  return _buildEmptyActivityState();
                }

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const Text(
                            'Activity',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap a ride to see details',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),

                    if (activeRides.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildActiveRideCard(activeRides.first),
                            const SizedBox(height: 24),
                          ]),
                        ),
                      ),

                    if (pastRides.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          24.0,
                          8.0,
                          24.0,
                          12.0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Text(
                              'Past Rides',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ]),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildPastRideCard(pastRides[index]);
                        }, childCount: pastRides.length),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 36)),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedActivity) return;
    _hasLoadedActivity = true;
    unawaited(_loadActivity());
  }

  Widget _buildActiveRideCard(RideHistoryModel ride) {
    final statusType = _resolveStatusType(ride.status);
    final timeStr = _formatTime(ride.date);

    return InkWell(
      onTap: () => _onCardAction(statusType, ride),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.neutralColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderSide.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppTheme.inProgress),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'On the Way',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.inProgress,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              if (timeStr.isNotEmpty) ...[
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Icon(
                                LucideIcons.chevron_right,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.tertiaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 18,
                                color: AppTheme.outlineBorderColor,
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride.pickup,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ride.destination,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppTheme.borderSide),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ride.vehicleType.toLowerCase().contains('share')
                                ? 'Shared ride, cash'
                                : 'Solo ride, cash',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          Text(
                            ride.price,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Activity',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to view your ride history',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ]),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(isGuest: true),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isGuest}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGuest ? 'Guest mode' : 'No rides yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isGuest
                  ? 'Sign in to view your recent trips.'
                  : 'Your completed and canceled trips will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.wifi_off,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _loadActivity,
              icon: const Icon(LucideIcons.refresh_cw, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Activity',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a ride to see details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ]),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(isGuest: false),
        ),
      ],
    );
  }

  Widget _buildLoadingState({required int itemCount}) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: -1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap a ride to see details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tertiaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: Skeletonizer.sliver(
            child: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLoadingRideCard(),
                childCount: itemCount,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }

  Widget _buildLoadingRideCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide.withValues(alpha: 0.2)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Bone.circle(size: 40),
                SizedBox(width: 14),
                Expanded(child: Bone.text(width: 150, fontSize: 15)),
                SizedBox(width: 12),
                Bone.text(width: 52, fontSize: 11),
              ],
            ),
            SizedBox(height: 16),
            Bone.multiText(lines: 2, fontSize: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildPastRideCard(RideHistoryModel ride) {
    final statusType = _resolveStatusType(ride.status);
    final dateStr = _formatPastRideDate(ride.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _onCardAction(statusType, ride),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderSide.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.check,
                  color: AppTheme.surface,
                  size: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateStr, cash',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.displayDriverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Text(
                    ride.price,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevron_right,
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPastRideDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final months = [
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
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return rawDate;
    }
  }

  String _formatTime(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final hourNum = dt.hour > 12
          ? dt.hour - 12
          : (dt.hour == 0 ? 12 : dt.hour);
      final periodStr = dt.hour >= 12 ? 'PM' : 'AM';
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      return '$hourNum:$minuteStr $periodStr';
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadActivity() async {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    final activityBloc = BlocProvider.of<ActivityBloc>(context);
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      activityBloc.add(LoadActivityEvent(passengerId: passengerId));
    }
  }

  void _onCardAction(String statusType, RideHistoryModel ride) {
    switch (statusType) {
      case 'progress':
      case 'accepted':
        unawaited(
          context.pushNamed(ActivityRoutes.activityTrackDriver, extra: ride),
        );
      case 'completed':
        unawaited(
          context.pushNamed(ActivityRoutes.activityViewDetails, extra: ride),
        );
      default:
        unawaited(context.pushNamed(TripRoutes.searchDestination));
    }
  }

  String _resolveStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'completed';
      case 'canceled':
      case 'cancelled':
        return 'canceled';
      case 'in_progress':
        return 'progress';
      case 'accepted':
        return 'accepted';
      default:
        return 'requested';
    }
  }
}

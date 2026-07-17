import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/trip_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() =>
      _PassengerActivityScreenState();
}

class _PassengerActivityScreenState extends State<PassengerActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ActivityBloc _bloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));

    _bloc = Modular.get<ActivityBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_loadActivity());
  }

  Future<void> _loadActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final passengerId = prefs.getString('passenger_id') ?? '';
    if (passengerId.isNotEmpty) {
      _bloc.add(LoadActivityEvent(passengerId: passengerId));
    } else {
      _bloc.add(LoadActivityEvent(passengerId: ''));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivityBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Activity',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
              letterSpacing: -1.5,
            ),
          ),
        ),
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTabBar(),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ActivityBloc, ActivityState>(
                  builder: (context, state) {
                    if (state is ActivityLoading) {
                      return _buildLoadingList();
                    }
                    if (state is ActivityError) {
                      return _buildErrorState(state.message);
                    }
                    if (state is ActivityLoaded) {
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRideList(state.past, isPast: true),
                          _buildRideList(state.upcoming, isPast: false),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.outlineBorderColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(26),
          ),
          labelColor: AppTheme.selectedItemColor,
          unselectedLabelColor: AppTheme.unselectedItemColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Past'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList(List<RideHistoryModel> rides, {required bool isPast}) {
    if (rides.isEmpty) {
      return _buildEmptyState(
        isPast ? 'No past rides yet' : 'No upcoming rides',
        isPast
            ? 'Your completed and canceled trips will appear here.'
            : 'Active and scheduled trips will appear here.',
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadActivity,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rides.length,
        itemBuilder: (context, index) => _buildActivityCard(rides[index]),
      ),
    );
  }

  Widget _buildActivityCard(RideHistoryModel ride) {
    final statusType = _resolveStatusType(ride.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ride.date,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.unselectedItemColor,
                ),
              ),
              _buildStatusBadge(ride.status, statusType),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppTheme.outlineBorderColor,
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppTheme.tertiaryColor,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.pickup,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ride.destination,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ride.price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.directions_car,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              TextButton(
                onPressed: () => _onCardAction(statusType, ride),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 10,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _actionLabel(statusType),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, String statusType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBgColor(statusType),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _statusTextColor(statusType),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
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
              Icons.wifi_off_rounded,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _loadActivity,
              icon: const Icon(Icons.refresh),
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

  Color _statusBgColor(String statusType) {
    switch (statusType) {
      case 'completed':
        return AppTheme.complete.withValues(alpha: 0.5);
      case 'progress':
      case 'accepted':
        return AppTheme.inProgress;
      default:
        return AppTheme.cancel;
    }
  }

  Color _statusTextColor(String statusType) => AppTheme.surface;

  String _actionLabel(String statusType) {
    switch (statusType) {
      case 'progress':
      case 'accepted':
        return 'Track Driver';
      case 'completed':
        return 'View Details';
      default:
        return 'Rebook';
    }
  }

  void _onCardAction(String statusType, RideHistoryModel ride) {
    switch (statusType) {
      case 'progress':
      case 'accepted':
        unawaited(context.pushNamed(TripRoutes.activityTrackDriver, extra: ride));
      case 'completed':
        unawaited(context.pushNamed(TripRoutes.activityViewDetails, extra: ride));
      default:
        unawaited(context.pushNamed(TripRoutes.searchDestination));
    }
  }
}

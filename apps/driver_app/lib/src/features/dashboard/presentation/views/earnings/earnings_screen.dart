import 'package:core_models/core_models.dart';
import 'package:driver_app/src/core/di/service_locator.dart';
import 'package:driver_app/src/features/dashboard/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/driver_dispatch/driver_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

/// Earnings Screen component defining application state or layout.
class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = true;
  double _weekTotal = 0;
  int _weekTripsCount = 0;
  double _hoursOnline = 0;
  String _rating = '4.9';

  List<_EarnDay> _dailyData = const [
    _EarnDay('Mon', 0),
    _EarnDay('Tue', 0),
    _EarnDay('Wed', 0),
    _EarnDay('Thu', 0),
    _EarnDay('Fri', 0),
    _EarnDay('Sat', 0),
    _EarnDay('Sun', 0),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id') ?? '';
    final cachedRating = prefs.getString('rating') ?? '4.9';
    if (mounted) {
      setState(() {
        _rating = cachedRating;
      });
    }

    if (driverId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final result = await getIt<DriverActivityRepository>().fetchTripHistory(
      driverId,
    );
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    List<dynamic> completedTrips = [];
    result.fold((failure) {}, (trips) {
      completedTrips = trips
          .where(
            (t) =>
                RideStatus.fromString(t['status'] as String? ?? '') ==
                RideStatus.completed,
          )
          .toList();
    });
    final thisWeekTrips = completedTrips.where((t) {
      try {
        final dt = DateTime.parse(t['created_at'] as String? ?? '').toLocal();
        return dt.isAfter(startOfWeek) || dt.isAtSameMomentAs(startOfWeek);
      } catch (_) {
        return false;
      }
    }).toList();

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dailyAmounts = <String, double>{
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    double total = 0;
    for (final t in thisWeekTrips) {
      try {
        final dt = DateTime.parse(t['created_at'] as String? ?? '').toLocal();
        final dayName = days[dt.weekday - 1];
        final fare = (t['fare'] as num?)?.toDouble() ?? 0.0;
        dailyAmounts[dayName] = (dailyAmounts[dayName] ?? 0) + fare;
        total += fare;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _dailyData = days
            .map((day) => _EarnDay(day, dailyAmounts[day] ?? 0.0))
            .toList();
        _weekTotal = total;
        _weekTripsCount = thisWeekTrips.length;
        _hoursOnline = _weekTripsCount > 0
            ? (_weekTripsCount * 0.75 + 0.5)
            : 0.0;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text(
                    'Earnings',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildWeekCard(_weekTotal),
                  const SizedBox(height: 20),
                  _buildPeriodTabs(),
                  const SizedBox(height: 24),
                  const Text(
                    'Daily Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBarChart(),
                  const SizedBox(height: 28),
                  _buildTripHistoryTile(),
                ],
              ),
      ),
    );
  }

  Widget _buildWeekCard(double weekTotal) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${weekTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('$_weekTripsCount', 'Trips'),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _miniStat('${_hoursOnline.toStringAsFixed(1)}h', 'Online'),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _miniStat('★ $_rating', 'Rating'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.primaryColor.withValues(alpha: 0.5),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxAmount = _dailyData
        .map((d) => d.amount)
        .reduce((a, b) => a > b ? a : b);
    final divisor = maxAmount > 0 ? maxAmount : 1.0;
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _dailyData.map((d) {
          final isToday = d.day == 'Sun';
          final barH = (d.amount / divisor) * 140;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '₱${d.amount.toInt()}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor.withValues(
                        alpha: isToday ? 0.8 : 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    height: barH,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripHistoryTile() {
    return GestureDetector(
      onTap: () => context.pushNamed(DriverRoutes.driverTripHistory),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.history,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'View all your past rides',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              size: 16,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnDay {
  final String day;
  final double amount;
  const _EarnDay(this.day, this.amount);
}

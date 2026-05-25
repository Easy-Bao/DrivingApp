import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Redesigned earnings screen — data-driven layout ready for repository injection.
class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _dailyData = const [
    _EarnDay('Mon', 120),
    _EarnDay('Tue', 280),
    _EarnDay('Wed', 195),
    _EarnDay('Thu', 340),
    _EarnDay('Fri', 410),
    _EarnDay('Sat', 520),
    _EarnDay('Sun', 385),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekTotal = _dailyData.fold<double>(0, (s, e) => s + e.amount);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: ListView(
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
            _buildWeekCard(weekTotal),
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
              _miniStat('24', 'Trips'),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _miniStat('18.5h', 'Online'),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _miniStat('★ 4.9', 'Rating'),
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
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _dailyData.map((d) {
          final isToday = d.day == 'Sun';
          final barH = (d.amount / maxAmount) * 140;
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
      onTap: () => context.pushNamed('DriverTripHistory'),
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

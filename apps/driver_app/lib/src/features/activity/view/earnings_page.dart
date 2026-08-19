import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _EarningsPeriod { daily, weekly, monthly }

class DriverEarningsPage extends StatefulWidget {
  const DriverEarningsPage({super.key});

  @override
  State<DriverEarningsPage> createState() => _DriverEarningsPageState();
}

class _DriverEarningsPageState extends State<DriverEarningsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _isLoading = true;
  String? _errorMessage;
  _EarningsPeriod _selectedPeriod = _EarningsPeriod.weekly;
  double _periodTotal = 0;
  int _periodTripsCount = 0;
  String _rating = '—';
  List<Map<String, dynamic>> _completedTrips = const [];
  List<_EarnDay> _dailyData = const [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: _EarningsPeriod.values.length,
      initialIndex: _selectedPeriod.index,
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final secureSession = Modular.get<SecureSessionService>();
    final driverId = await secureSession.readDriverId() ?? '';
    final prefs = await SharedPreferences.getInstance();
    final rating = prefs.getString('rating') ?? '—';

    if (driverId.isEmpty) {
      if (mounted) {
        setState(() {
          _rating = rating;
          _isLoading = false;
          _errorMessage = 'Your driver session is unavailable.';
        });
      }
      return;
    }

    final result = await Modular.get<IDriverActivityRepository>()
        .fetchTripHistory(driverId);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _rating = rating;
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (trips) {
        final completedTrips = trips
            .where(
              (trip) =>
                  trip is Map &&
                  RideStatus.fromString(trip['status'] as String? ?? '') ==
                      RideStatus.completed,
            )
            .map((trip) => Map<String, dynamic>.from(trip as Map))
            .toList();
        final summary = _buildSummary(_selectedPeriod, completedTrips);
        setState(() {
          _rating = rating;
          _completedTrips = completedTrips;
          _applySummary(summary);
          _isLoading = false;
        });
      },
    );
  }

  void _selectPeriod(int index) {
    final period = _EarningsPeriod.values[index];
    if (_selectedPeriod == period) return;
    final summary = _buildSummary(period, _completedTrips);
    setState(() {
      _selectedPeriod = period;
      _applySummary(summary);
    });
  }

  void _applySummary(_EarningsSummary summary) {
    _periodTotal = summary.total;
    _periodTripsCount = summary.tripsCount;
    _dailyData = summary.days;
  }

  _EarningsSummary _buildSummary(
    _EarningsPeriod period,
    List<Map<String, dynamic>> trips,
  ) {
    final now = DateTime.now();
    final today = _startOfDay(now);
    late DateTime start;
    late DateTime end;
    late List<_EarnDay> days;

    switch (period) {
      case _EarningsPeriod.daily:
        start = today;
        end = today.add(const Duration(days: 1));
        days = [_EarnDay('Today', 0, isCurrent: true)];
      case _EarningsPeriod.weekly:
        start = _startOfWeek(now);
        end = start.add(const Duration(days: 7));
        days = List.generate(7, (index) {
          final date = start.add(Duration(days: index));
          return _EarnDay(_weekdayLabel(date.weekday), 0, date: date);
        });
      case _EarningsPeriod.monthly:
        start = DateTime(now.year, now.month);
        end = DateTime(now.year, now.month + 1);
        days = List.generate(5, (index) {
          final weekStart = start.add(Duration(days: index * 7));
          return _EarnDay(
            'W${index + 1}',
            0,
            date: weekStart,
            isCurrent:
                now.year == start.year &&
                now.month == start.month &&
                ((now.day - 1) ~/ 7) == index,
          );
        });
    }

    final amounts = List<double>.filled(days.length, 0);
    var tripsCount = 0;

    for (final trip in trips) {
      final tripDate = _tripDate(trip);
      if (tripDate == null ||
          tripDate.isBefore(start) ||
          !tripDate.isBefore(end)) {
        continue;
      }

      tripsCount++;
      final fare = driverFareInPesos(trip);
      if (fare != null) {
        final index = switch (period) {
          _EarningsPeriod.daily => 0,
          _EarningsPeriod.weekly => tripDate.weekday - 1,
          _EarningsPeriod.monthly => ((tripDate.day - 1) ~/ 7).clamp(0, 4),
        };
        amounts[index] += fare;
      }
    }

    final summaryDays = [
      for (var index = 0; index < days.length; index++)
        days[index].copyWith(amount: amounts[index]),
    ];
    return _EarningsSummary(
      total: amounts.fold(0, (sum, amount) => sum + amount),
      tripsCount: tripsCount,
      days: summaryDays,
    );
  }

  DateTime? _tripDate(Map<String, dynamic> trip) {
    final rawDate =
        driverValueAsString(trip['completed_at']) ??
        driverValueAsString(trip['created_at']);
    if (rawDate == null) return null;
    try {
      return DateTime.parse(rawDate).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _startOfWeek(DateTime value) {
    final day = _startOfDay(value);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  String get _periodTitle {
    switch (_selectedPeriod) {
      case _EarningsPeriod.daily:
        return 'TODAY';
      case _EarningsPeriod.weekly:
        return 'THIS WEEK';
      case _EarningsPeriod.monthly:
        return 'THIS MONTH';
    }
  }

  String get _breakdownTitle {
    switch (_selectedPeriod) {
      case _EarningsPeriod.daily:
        return 'Today';
      case _EarningsPeriod.weekly:
        return 'Daily Breakdown';
      case _EarningsPeriod.monthly:
        return 'Weekly Breakdown';
    }
  }

  String get _breakdownDescription => switch (_selectedPeriod) {
    _EarningsPeriod.daily => 'Your earnings from completed rides today.',
    _EarningsPeriod.weekly => 'See how your total builds each day.',
    _EarningsPeriod.monthly => 'See how your total builds each week.',
  };

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background,
        title: const Text('Earnings'),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _errorMessage != null
            ? _buildErrorState()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? 16.0
                      : 24.0;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      16,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSummaryCard(),
                                const SizedBox(height: 12),
                                _buildBarChart(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            const Text(
              'Earnings are unavailable',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We could not load your completed rides. Try again when you have a stable connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor.withValues(alpha: 0.58),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _periodTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.62),
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₱${_periodTotal.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.2,
              ),
            ),
            Text(
              'Earnings from your completed rides',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.56),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _miniStat('$_periodTripsCount', 'Completed trips'),
                ),
                _summaryDivider(),
                Expanded(child: _miniStat(_rating, 'Driver rating')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return SizedBox(
      height: 32,
      child: TabBar(
        controller: _tabCtrl,
        onTap: _selectPeriod,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 18),
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.primaryColor.withValues(alpha: 0.45),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chartHeight = constraints.maxWidth < 360 ? 150.0 : 166.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _breakdownTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _breakdownDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                _buildPeriodTabs(),
                const SizedBox(height: 4),
                SizedBox(
                  height: chartHeight,
                  child: LayoutBuilder(
                    builder: (context, chartConstraints) {
                      return BarChart(
                        _barChartData(chartConstraints.maxWidth),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  BarChartData _barChartData(double availableWidth) {
    final chartDays = _dailyData.isEmpty
        ? const [_EarnDay('—', 0)]
        : _dailyData;
    final maxAmount = chartDays.fold<double>(0, (max, item) {
      final amount = item.amount;
      if (!amount.isFinite || amount <= max) return max;
      return amount;
    });
    final maxY = maxAmount > 0 ? maxAmount * 1.25 : 1.0;
    final placeholderHeight = maxAmount > 0 ? maxAmount * 0.025 : 0.025;
    final barWidth = (availableWidth / (chartDays.length * 2.2))
        .clamp(14.0, 34.0)
        .toDouble();

    return BarChartData(
      minY: 0,
      maxY: maxY,
      alignment: BarChartAlignment.spaceEvenly,
      groupsSpace: 8,
      backgroundColor: Colors.transparent,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppTheme.borderSide.withValues(alpha: 0.72),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= chartDays.length) {
                return const SizedBox.shrink();
              }
              final day = chartDays[index];
              return SideTitleWidget(
                meta: meta,
                space: 5,
                child: Text(
                  day.day,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: day.isCurrent
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.42),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(enabled: false),
      barGroups: [
        for (var index = 0; index < chartDays.length; index++)
          _buildBarGroup(
            chartDays[index],
            index,
            maxAmount,
            placeholderHeight,
            barWidth,
          ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(
    _EarnDay day,
    int index,
    double maxAmount,
    double placeholderHeight,
    double barWidth,
  ) {
    final amount = day.amount.isFinite && day.amount > 0 ? day.amount : 0.0;
    final barValue = amount > 0 ? amount : placeholderHeight;
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: barValue,
          width: barWidth,
          color: day.isCurrent
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.16),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          label: BarChartRodLabel(
            show: true,
            text: '₱${day.amount.toInt()}',
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(
                alpha: day.isCurrent ? 0.82 : 0.48,
              ),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
            offset: const Offset(0, 6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: maxAmount > 0,
            toY: maxAmount,
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}

class _EarningsSummary {
  final double total;
  final int tripsCount;
  final List<_EarnDay> days;

  const _EarningsSummary({
    required this.total,
    required this.tripsCount,
    required this.days,
  });
}

class _EarnDay {
  final String day;
  final double amount;
  final DateTime? date;
  final bool isCurrent;

  const _EarnDay(this.day, this.amount, {this.date, this.isCurrent = false});

  _EarnDay copyWith({double? amount}) => _EarnDay(
    day,
    amount ?? this.amount,
    date: date,
    isCurrent: isCurrent || (date != null && _sameDay(date!, DateTime.now())),
  );
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

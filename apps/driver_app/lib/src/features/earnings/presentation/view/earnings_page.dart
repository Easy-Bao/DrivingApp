import 'package:driver_app/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

enum _EarningsPeriod { daily, weekly, monthly }

class DriverEarningsPage extends StatefulWidget {
  const DriverEarningsPage({super.key});

  @override
  State<DriverEarningsPage> createState() => _DriverEarningsPageState();
}

class _DriverEarningsPageState extends State<DriverEarningsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  _EarningsPeriod _selectedPeriod = _EarningsPeriod.weekly;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: _EarningsPeriod.values.length,
      initialIndex: _selectedPeriod.index,
      vsync: this,
    );
  }

  void _selectPeriod(int index) {
    final period = _EarningsPeriod.values[index];
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
  }

  Map<_EarningsPeriod, _EarningsSummary> _parseSummaries(
    Map<String, dynamic> data,
  ) {
    final today = _parsePeriod(data['today']);
    final week = _parsePeriod(data['this_week']);
    final month = _parsePeriod(data['this_month']);
    final now = DateTime.now();
    final weekdays = _parseBuckets(
      data['weekdays'],
      (index, date) => _weekdayLabel(date?.weekday ?? index + 1),
      now,
    );
    final monthWeeks = _parseBuckets(
      data['month_weeks'],
      (index, _) => 'W${index + 1}',
      now,
      currentIndex: (now.day - 1) ~/ 7,
    );
    return {
      _EarningsPeriod.daily: _EarningsSummary(
        total: today.total,
        tripsCount: today.tripsCount,
        days: [_EarnDay('Today', today.total, isCurrent: true)],
      ),
      _EarningsPeriod.weekly: _EarningsSummary(
        total: week.total,
        tripsCount: week.tripsCount,
        days: weekdays,
      ),
      _EarningsPeriod.monthly: _EarningsSummary(
        total: month.total,
        tripsCount: month.tripsCount,
        days: monthWeeks,
      ),
    };
  }

  _EarningsSummary _parsePeriod(Object? raw) {
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    return _EarningsSummary(
      total: SafeParse.toDouble(data['earnings_centavos']) / 100,
      tripsCount: SafeParse.toInt(data['completed_trips']),
      days: const [],
    );
  }

  List<_EarnDay> _parseBuckets(
    Object? raw,
    String Function(int index, DateTime? date) label,
    DateTime now, {
    int? currentIndex,
  }) {
    if (raw is! List) return const [];
    return [
      for (var index = 0; index < raw.length; index++)
        if (raw[index] is Map)
          _bucketDay(
            Map<String, dynamic>.from(raw[index] as Map),
            label,
            index,
            now,
            currentIndex,
          ),
    ];
  }

  _EarnDay _bucketDay(
    Map<String, dynamic> bucket,
    String Function(int index, DateTime? date) label,
    int index,
    DateTime now,
    int? currentIndex,
  ) {
    final date = DateTime.tryParse(
      SafeParse.toStringValue(bucket['start_date']),
    );
    return _EarnDay(
      label(index, date),
      SafeParse.toDouble(bucket['earnings_centavos']) / 100,
      isCurrent: currentIndex == index || (date != null && _sameDay(date, now)),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  String get _periodTitle {
    switch (_selectedPeriod) {
      case _EarningsPeriod.daily:
        return 'Today';
      case _EarningsPeriod.weekly:
        return 'This Week';
      case _EarningsPeriod.monthly:
        return 'This Month';
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

  String _averageFareLabel(_EarningsSummary summary) => summary.tripsCount == 0
      ? '—'
      : formatPesoAmount(summary.total / summary.tripsCount);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DriverEarningsCubit>().state;
    final summaries = state.data == null
        ? const <_EarningsPeriod, _EarningsSummary>{}
        : _parseSummaries(state.data!);
    final summary = summaries[_selectedPeriod];

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: context.canvasColor,
        title: const Text('Earnings'),
      ),
      body: SafeArea(
        top: false,
        child: summary == null
            ? state.errorMessage != null
                  ? _buildErrorState(context)
                  : Center(
                      child: CircularProgressIndicator(
                        color: context.colorScheme.onSurface,
                      ),
                    )
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
                          child: Skeletonizer(
                            enabled: state.isLoading,
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSummaryCard(summary),
                                  const SizedBox(height: 12),
                                  _buildBarChart(summary.days),
                                ],
                              ),
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

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: context.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Earnings are unavailable',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We could not load your earnings summary. Try again when you have a stable connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () =>
                  BlocProvider.of<DriverEarningsCubit>(context).load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(_EarningsSummary summary) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colorScheme.primary, context.colorScheme.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.onSurface.withValues(alpha: 0.16),
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
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onPrimary,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatPesoAmount(summary.total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onPrimary,
                letterSpacing: -1.2,
              ),
            ),
            Text(
              'Earnings from your completed rides',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _miniStat('${summary.tripsCount}', 'Completed trips'),
                ),
                _summaryDivider(),
                Expanded(
                  child: _miniStat(
                    _averageFareLabel(summary),
                    'Average per trip',
                  ),
                ),
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
      color: context.colorScheme.onPrimary.withValues(alpha: 0.24),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onPrimary,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: context.colorScheme.onPrimary,
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
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: context.colorScheme.onSurface,
            width: 2,
          ),
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 18),
        labelColor: context.colorScheme.onSurface,
        unselectedLabelColor: context.colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: context.colorScheme.surface.withValues(alpha: 0),
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<_EarnDay> dailyData) {
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _breakdownDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colorScheme.onSurfaceVariant,
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
                        _barChartData(chartConstraints.maxWidth, dailyData),
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

  BarChartData _barChartData(double availableWidth, List<_EarnDay> dailyData) {
    final chartDays = dailyData.isEmpty ? const [_EarnDay('—', 0)] : dailyData;
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
      backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.72),
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
                        ? context.colorScheme.onSurface
                        : context.colorScheme.onSurfaceVariant,
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
              ? context.colorScheme.onSurface
              : context.colorScheme.onSurface.withValues(alpha: 0.16),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          label: BarChartRodLabel(
            show: true,
            text: '₱${day.amount.toInt()}',
            style: TextStyle(
              color: day.isCurrent
                  ? context.colorScheme.onSurface
                  : context.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            offset: const Offset(0, 6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: false,
            toY: maxAmount,
            color: context.colorScheme.onSurface.withValues(alpha: 0.05),
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
  final bool isCurrent;

  const _EarnDay(this.day, this.amount, {this.isCurrent = false});
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

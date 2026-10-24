import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/driver_earnings_summary.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  EarningsPeriod _selectedPeriod = EarningsPeriod.weekly;
  bool _showAll = false;

  String get _periodTitle => switch (_selectedPeriod) {
    EarningsPeriod.daily => 'Today',
    EarningsPeriod.weekly => 'This week',
    EarningsPeriod.monthly => 'This month',
  };

  String _dateLabel(DateTime date) =>
      MaterialLocalizations.of(context).formatShortMonthDay(date);

  String _periodCaption(EarningsPeriodSummary summary) {
    final dates = summary.days.map((day) => day.startDate).nonNulls.toList();
    if (dates.isEmpty || _selectedPeriod == EarningsPeriod.daily) {
      return _periodTitle;
    }
    if (_selectedPeriod == EarningsPeriod.monthly) {
      return '$_periodTitle · ${MaterialLocalizations.of(context).formatMonthYear(dates.first)}';
    }
    return '$_periodTitle · ${_dateLabel(dates.first)} – ${_dateLabel(dates.last)}';
  }

  String _rideCount(int count) =>
      '$count completed ${count == 1 ? 'ride' : 'rides'}';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EarningsCubit>().state;
    final summary = state.data?.summaryFor(_selectedPeriod);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: context.canvasColor,
        title: const Text('Earnings'),
      ),
      body: SafeArea(
        top: false,
        child: summary == null && state.errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: context.read<EarningsCubit>().load,
                child: LayoutBuilder(
                  builder: (context, constraints) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 360
                          ? AppSpacing.md
                          : AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: summary == null
                              ? _buildLoadingState()
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (state.errorMessage != null)
                                      AppErrorBanner(
                                        message: state.errorMessage!,
                                        onRetry: context
                                            .read<EarningsCubit>()
                                            .load,
                                        onDismiss: context
                                            .read<EarningsCubit>()
                                            .dismissError,
                                      ),
                                    _buildSummary(summary),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildPeriodTabs(),
                                    const SizedBox(height: AppSpacing.xl),
                                    Semantics(
                                      label:
                                          'Earnings chart. ${summary.days.map((day) => '${day.day}: ${formatPesoAmount(day.amount)}').join('. ')}',
                                      child: ExcludeSemantics(
                                        child: SizedBox(
                                          height: 190,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) =>
                                                BarChart(
                                                  _barChartData(
                                                    constraints.maxWidth,
                                                    summary.days,
                                                  ),
                                                  duration:
                                                      MediaQuery.disableAnimationsOf(
                                                        context,
                                                      )
                                                      ? Duration.zero
                                                      : const Duration(
                                                          milliseconds: 200,
                                                        ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildStats(summary),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildRecent(summary),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() => const Skeletonizer(
    key: ValueKey<String>('driver-earnings-loading-skeleton'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Bone.text(width: 160),
        SizedBox(height: AppSpacing.md),
        Bone.text(width: 220, fontSize: 48),
        SizedBox(height: AppSpacing.lg),
        Bone.square(size: 190),
      ],
    ),
  );

  Widget _buildErrorState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Earnings are unavailable',
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'We could not load your earnings. Please try again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: context.read<EarningsCubit>().load,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildSummary(EarningsPeriodSummary summary) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _periodCaption(summary),
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          formatPesoAmount(summary.total),
          style: context.textStyles.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: summary.total < 0
                ? context.colorScheme.error
                : context.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'From ${_rideCount(summary.tripsCount)}',
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      if (summary.total < 0) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Adjustment',
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colorScheme.error,
          ),
        ),
        const Text('Fee deductions or dispute adjustments applied'),
      ],
    ],
  );

  Widget _buildPeriodTabs() => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        for (final (index, label) in ['Day', 'Week', 'Month'].indexed)
          Expanded(
            child: Semantics(
              selected: _selectedPeriod.index == index,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: _selectedPeriod.index == index
                      ? context.colorScheme.surface
                      : Colors.transparent,
                  foregroundColor: _selectedPeriod.index == index
                      ? context.colorScheme.onSurface
                      : context.colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                onPressed: () => setState(() {
                  _selectedPeriod = EarningsPeriod.values[index];
                  _showAll = false;
                }),
                child: Text(label),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildStats(EarningsPeriodSummary summary) {
    final active = summary.days.where((day) => day.tripsCount > 0).length;
    final stats = [
      ('Trips', '${summary.tripsCount}'),
      (
        'Avg per trip',
        summary.tripsCount == 0
            ? '—'
            : formatPesoAmount(summary.total / summary.tripsCount),
      ),
      (
        _selectedPeriod == EarningsPeriod.monthly
            ? 'Active weeks'
            : 'Active days',
        '$active of ${summary.days.length}',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final children = [
            for (final (label, value) in stats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      value,
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ];
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final child in children) Expanded(child: child),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildRecent(EarningsPeriodSummary summary) {
    final recent = summary.days
        .where((day) => day.tripsCount > 0 || day.amount != 0)
        .toList()
        .reversed
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (recent.length > 3)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? 'Show less' : 'See all'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (recent.isEmpty)
          Text(
            'No completed rides this period.',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final day in _showAll ? recent : recent.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: context.colorScheme.surfaceContainerHighest,
                  foregroundColor: context.colorScheme.onSurface,
                  child: ExcludeSemantics(
                    child: Icon(
                      day.amount < 0
                          ? Icons.remove_rounded
                          : Icons.check_rounded,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final amount = Text(
                        '${day.amount > 0 ? '+' : ''}${formatPesoAmount(day.amount)}',
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      );
                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.startDate == null
                                ? day.day
                                : '${_selectedPeriod == EarningsPeriod.monthly ? 'Week of ' : ''}${_dateLabel(day.startDate!)}',
                            style: context.textStyles.titleSmall,
                          ),
                          if (day.tripsCount > 0)
                            Text(
                              _rideCount(day.tripsCount),
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      );
                      if (MediaQuery.textScalerOf(context).scale(14) > 20 ||
                          constraints.maxWidth < 220) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [details, amount],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: AppSpacing.sm),
                          amount,
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  BarChartData _barChartData(
    double availableWidth,
    List<EarnDayBucket> dailyData,
  ) {
    final chartDays = dailyData.isEmpty
        ? const [EarnDayBucket(day: '—', amount: 0)]
        : dailyData;
    final maxAmount = chartDays.fold<double>(0, (max, item) {
      final amount = item.amount.abs();
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
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: [3, 5],
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
                  style: context.textStyles.labelSmall?.copyWith(
                    fontWeight: day.isCurrent
                        ? FontWeight.w800
                        : FontWeight.w600,
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
    EarnDayBucket day,
    int index,
    double maxAmount,
    double placeholderHeight,
    double barWidth,
  ) {
    final isNegative = day.amount < 0;
    final amount = day.amount.isFinite && !isNegative ? day.amount : 0.0;
    final barValue = isNegative
        ? (day.amount.abs() > 0 ? day.amount.abs() : placeholderHeight)
        : (amount > 0 ? amount : placeholderHeight);
    final rodColor = isNegative
        ? (day.isCurrent
              ? context.colorScheme.error
              : context.colorScheme.error.withValues(alpha: 0.5))
        : (day.isCurrent
              ? context.colorScheme.primary
              : (day.amount == 0
                    ? context.colorScheme.outlineVariant
                    : context.colorScheme.primary));
    final labelColor = isNegative
        ? context.colorScheme.error
        : (day.isCurrent
              ? context.colorScheme.primary
              : context.colorScheme.onSurfaceVariant);

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: barValue,
          width: barWidth,
          color: rodColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          label: BarChartRodLabel(
            show: day.amount != 0,
            text: formatPesoAmount(day.amount),
            style: context.textStyles.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              fontFeatures: const [FontFeature.tabularFigures()],
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

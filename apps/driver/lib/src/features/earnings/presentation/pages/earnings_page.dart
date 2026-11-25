import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/earnings_summary.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:driver/src/features/earnings/presentation/widgets/earnings_period_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
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
      body: SafeArea(
        child: summary == null && state.errorMessage != null
            ? _buildErrorState(state.errorMessage!)
            : RefreshIndicator(
                color: context.colorScheme.onSurface,
                onRefresh: context.read<EarningsCubit>().load,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 360
                        ? AppSpacing.lg
                        : AppLayout.pagePaddingWide;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.sm,
                        horizontalPadding,
                        AppSpacing.xxxl,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppLayout.pageMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const AppPageHeader(title: 'Earnings'),
                                const SizedBox(height: AppSpacing.xl),
                                if (summary == null)
                                  _buildLoadingState()
                                else
                                  _buildContent(
                                    summary,
                                    errorMessage: state.errorMessage,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  static const _loadingSummary = EarningsPeriodSummary(
    total: 88.88,
    tripsCount: 3,
    days: [
      EarnDayBucket(day: 'Mon', amount: 30, tripsCount: 1),
      EarnDayBucket(day: 'Tue', amount: 20, tripsCount: 1),
      EarnDayBucket(day: 'Wed', amount: 38.88, tripsCount: 1),
      EarnDayBucket(day: 'Thu', amount: 0),
      EarnDayBucket(day: 'Fri', amount: 0),
      EarnDayBucket(day: 'Sat', amount: 0),
      EarnDayBucket(day: 'Sun', amount: 0),
    ],
  );

  Widget _buildLoadingState() => ExcludeSemantics(
    child: Skeletonizer(
      key: const ValueKey<String>('driver-earnings-loading-skeleton'),
      child: _buildContent(_loadingSummary, isLoading: true),
    ),
  );

  Widget _buildContent(
    EarningsPeriodSummary summary, {
    String? errorMessage,
    bool isLoading = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (errorMessage != null) ...[
        AppErrorBanner(
          message: errorMessage,
          onRetry: context.read<EarningsCubit>().load,
          onDismiss: context.read<EarningsCubit>().dismissError,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      _buildSummary(summary),
      const SizedBox(height: AppSpacing.xl),
      EarningsPeriodBar(
        selectedPeriod: _selectedPeriod,
        onSelected: (period) {
          if (period == _selectedPeriod) return;
          setState(() {
            _selectedPeriod = period;
            _showAll = false;
          });
        },
      ),
      const SizedBox(height: AppSpacing.xl),
      Semantics(
        label:
            'Earnings chart. ${summary.days.map((day) => '${day.day}: ${formatPesoAmount(day.amount)}').join('. ')}',
        child: ExcludeSemantics(
          child: SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (context, constraints) => Skeleton.shade(
                child: BarChart(
                  _barChartData(constraints.maxWidth, summary.days),
                  duration: isLoading || MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      _buildStats(summary),
      const SizedBox(height: AppSpacing.xxl),
      _buildRecent(summary),
    ],
  );

  Widget _buildErrorState(String errorMessage) => AppRetryErrorView(
    title: 'Unable to load earnings',
    message: errorMessage,
    onRetry: context.read<EarningsCubit>().load,
  );

  Widget _buildSummary(EarningsPeriodSummary summary) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _periodCaption(summary),
          style: textStyles.bodySmall?.tabular.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatPesoAmount(summary.total),
            style: textStyles.displayLarge?.tabular.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: summary.total < 0
                  ? colorScheme.error
                  : colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'From ${_rideCount(summary.tripsCount)}',
          style: textStyles.bodySmall?.tabular.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (summary.total < 0) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ExcludeSemantics(
                    child: Icon(
                      LucideIcons.circle_alert,
                      size: 16,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adjustment',
                        style: textStyles.labelMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fee deductions or dispute adjustments applied',
                        style: textStyles.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats(EarningsPeriodSummary summary) {
    final colorScheme = context.colorScheme;
    final hairlineColor = colorScheme.outlineVariant.withValues(alpha: 0.7);
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: hairlineColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final items = [
            for (final (label, value) in stats)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: context.textStyles.titleMedium?.tabular.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
          ];

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: items[index],
                  ),
                  if (index != items.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: hairlineColor,
                      ),
                    ),
                ],
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : AppSpacing.md,
                        right: index == items.length - 1 ? 0 : AppSpacing.md,
                      ),
                      child: items[index],
                    ),
                  ),
                  if (index != items.length - 1)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: hairlineColor,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecent(EarningsPeriodSummary summary) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final recent = summary.days
        .where((day) => day.tripsCount > 0 || day.amount != 0)
        .toList()
        .reversed
        .toList();
    final visible = _showAll ? recent : recent.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Recent',
                  style: textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            if (recent.length > 3)
              TextButton(
                key: const ValueKey<String>('driver-earnings-toggle-recent'),
                onPressed: () => setState(() => _showAll = !_showAll),
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
                child: Text(_showAll ? 'Show less' : 'See all'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No completed rides this period.',
              style: textStyles.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (var index = 0; index < visible.length; index++) ...[
          _buildRecentRow(visible[index]),
          if (index != visible.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              indent: 52,
              color: colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
        ],
      ],
    );
  }

  Widget _buildRecentRow(EarnDayBucket day) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final isNegative = day.amount < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNegative
                      ? colorScheme.error.withValues(alpha: 0.35)
                      : colorScheme.outlineVariant,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                isNegative ? LucideIcons.minus : LucideIcons.arrow_up_right,
                size: 16,
                color: isNegative ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final amount = Text(
                  '${day.amount > 0 ? '+' : ''}${formatPesoAmount(day.amount)}',
                  style: textStyles.titleSmall?.tabular.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isNegative
                        ? colorScheme.error
                        : colorScheme.onSurface,
                  ),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.startDate == null
                          ? day.day
                          : '${_selectedPeriod == EarningsPeriod.monthly ? 'Week of ' : ''}${_dateLabel(day.startDate!)}',
                      style: textStyles.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (day.tripsCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        _rideCount(day.tripsCount),
                        style: textStyles.bodySmall?.tabular.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                );
                if (MediaQuery.textScalerOf(context).scale(14) > 20 ||
                    constraints.maxWidth < 220) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      const SizedBox(height: AppSpacing.xs),
                      amount,
                    ],
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
    );
  }

  BarChartData _barChartData(
    double availableWidth,
    List<EarnDayBucket> dailyData,
  ) {
    final colorScheme = context.colorScheme;
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
        .clamp(14.0, 32.0)
        .toDouble();

    return BarChartData(
      minY: 0,
      maxY: maxY,
      alignment: BarChartAlignment.spaceEvenly,
      groupsSpace: 8,
      backgroundColor: colorScheme.surface.withValues(alpha: 0),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          strokeWidth: 0.75,
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
            reservedSize: 26,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= chartDays.length) {
                return const SizedBox.shrink();
              }
              final day = chartDays[index];
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  day.day,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    fontWeight: day.isCurrent
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: day.isCurrent
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: const BarTouchData(enabled: false),
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
    final colorScheme = context.colorScheme;
    final isNegative = day.amount < 0;
    final amount = day.amount.isFinite && !isNegative ? day.amount : 0.0;
    final barValue = isNegative
        ? (day.amount.abs() > 0 ? day.amount.abs() : placeholderHeight)
        : (amount > 0 ? amount : placeholderHeight);
    final rodColor = isNegative
        ? (day.isCurrent
              ? colorScheme.error
              : colorScheme.error.withValues(alpha: 0.55))
        : (day.amount == 0
              ? colorScheme.outlineVariant.withValues(alpha: 0.6)
              : (day.isCurrent
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.72)));
    final labelColor = isNegative
        ? colorScheme.error
        : (day.isCurrent
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant);

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: barValue,
          width: barWidth,
          color: rodColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          label: BarChartRodLabel(
            show: day.amount != 0,
            text: formatPesoAmount(day.amount),
            style: context.textStyles.labelSmall?.tabular.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            offset: const Offset(0, 6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: false,
            toY: maxAmount,
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}

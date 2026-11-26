import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/earnings_summary.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const EarningsChartCard({
  super.key,
  required this.days,
  this.isLoading = false,
}) extends StatelessWidget {
  final List<EarnDayBucket> days;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Earnings chart. ${days.map((day) => '${day.day}: ${formatPesoAmount(day.amount)}').join('. ')}',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 190,
          child: LayoutBuilder(
            builder: (context, constraints) => Skeleton.shade(
              child: BarChart(
                _barChartData(context, constraints.maxWidth, days),
                duration: isLoading || MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BarChartData _barChartData(
    BuildContext context,
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
            context,
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
    BuildContext context,
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

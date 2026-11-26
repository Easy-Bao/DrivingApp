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
    final maxPositive = chartDays.fold<double>(0, (max, item) {
      if (!item.amount.isFinite || item.amount <= max) return max;
      return item.amount;
    });
    final maxNegative = chartDays.fold<double>(0, (max, item) {
      if (!item.amount.isFinite || item.amount >= 0) return max;
      final magnitude = -item.amount;
      return magnitude > max ? magnitude : max;
    });
    final hasNegative = maxNegative > 0;
    final minY = hasNegative ? -(maxNegative * 1.25) : 0.0;
    final maxY = hasNegative
        ? (maxPositive > 0 ? maxPositive * 1.25 : maxNegative * 0.35)
        : (maxPositive > 0 ? maxPositive * 1.25 : 1.0);
    final totalSpan = maxY - minY;
    final maxMagnitude = maxPositive > maxNegative ? maxPositive : maxNegative;
    final placeholderHeight = totalSpan > 0 ? totalSpan * 0.02 : 0.025;
    final barWidth = (availableWidth / (chartDays.length * 2.2))
        .clamp(14.0, 32.0)
        .toDouble();

    return BarChartData(
      minY: minY,
      maxY: maxY,
      alignment: BarChartAlignment.spaceEvenly,
      groupsSpace: 8,
      backgroundColor: colorScheme.surface.withValues(alpha: 0),
      borderData: FlBorderData(show: false),
      extraLinesData: hasNegative
          ? ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ],
            )
          : null,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: totalSpan / 4,
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
            maxMagnitude,
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
    final finiteAmount = day.amount.isFinite ? day.amount : 0.0;
    final isNegative = finiteAmount < 0;
    final barValue = isNegative
        ? finiteAmount
        : (finiteAmount > 0 ? finiteAmount : placeholderHeight);
    final rodColor = isNegative
        ? (day.isCurrent
              ? colorScheme.error
              : colorScheme.error.withValues(alpha: 0.55))
        : (finiteAmount == 0
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
          fromY: 0,
          toY: barValue,
          width: barWidth,
          color: rodColor,
          borderRadius: isNegative
              ? const BorderRadius.vertical(bottom: Radius.circular(5))
              : const BorderRadius.vertical(top: Radius.circular(5)),
          label: BarChartRodLabel(
            show: finiteAmount != 0,
            text: formatPesoAmount(finiteAmount),
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

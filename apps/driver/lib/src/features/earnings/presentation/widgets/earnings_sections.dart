import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/earnings_summary.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

String _rideCountLabel(int count) =>
    '$count completed ${count == 1 ? 'ride' : 'rides'}';

class const EarningsSummaryHeader({
  super.key,
  required this.summary,
  required this.selectedPeriod,
}) extends StatelessWidget {
  final EarningsPeriodSummary summary;
  final EarningsPeriod selectedPeriod;

  String _periodCaption(BuildContext context) {
    final periodTitle = switch (selectedPeriod) {
      EarningsPeriod.daily => 'Today',
      EarningsPeriod.weekly => 'This week',
      EarningsPeriod.monthly => 'This month',
    };
    final dates = summary.days.map((day) => day.startDate).nonNulls.toList();
    if (dates.isEmpty || selectedPeriod == EarningsPeriod.daily) {
      return periodTitle;
    }
    final localizations = MaterialLocalizations.of(context);
    if (selectedPeriod == EarningsPeriod.monthly) {
      return '$periodTitle · ${localizations.formatMonthYear(dates.first)}';
    }
    return '$periodTitle · ${localizations.formatShortMonthDay(dates.first)} – ${localizations.formatShortMonthDay(dates.last)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _periodCaption(context),
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
          'From ${_rideCountLabel(summary.tripsCount)}',
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
}

class const EarningsStatsSection({
  super.key,
  required this.summary,
  required this.selectedPeriod,
}) extends StatelessWidget {
  final EarningsPeriodSummary summary;
  final EarningsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
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
        selectedPeriod == EarningsPeriod.monthly
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
}

class const EarningsRecentList({
  super.key,
  required this.summary,
  required this.selectedPeriod,
  required this.showAll,
  required this.onToggleShowAll,
}) extends StatelessWidget {
  final EarningsPeriodSummary summary;
  final EarningsPeriod selectedPeriod;
  final bool showAll;
  final VoidCallback onToggleShowAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final recent = summary.days
        .where((day) => day.tripsCount > 0 || day.amount != 0)
        .toList()
        .reversed
        .toList();
    final visible = showAll ? recent : recent.take(3).toList();

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
                onPressed: onToggleShowAll,
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
                child: Text(showAll ? 'Show less' : 'See all'),
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
          _EarningsRecentRow(
            day: visible[index],
            selectedPeriod: selectedPeriod,
          ),
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
}

class const _EarningsRecentRow({
  required this.day,
  required this.selectedPeriod,
}) extends StatelessWidget {
  final EarnDayBucket day;
  final EarningsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final isNegative = day.amount < 0;
    final startDate = day.startDate;
    final dateTitle = startDate == null
        ? day.day
        : '${selectedPeriod == EarningsPeriod.monthly ? 'Week of ' : ''}${MaterialLocalizations.of(context).formatShortMonthDay(startDate)}';

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
                      dateTitle,
                      style: textStyles.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (day.tripsCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        _rideCountLabel(day.tripsCount),
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
}

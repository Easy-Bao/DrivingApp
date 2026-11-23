import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/earnings_summary.dart';
import 'package:material_ui/material_ui.dart';

class const EarningsPeriodBar({
  super.key,
  required this.selectedPeriod,
  required this.onSelected,
}) extends StatelessWidget {
  static const Duration _animationDuration = Duration(milliseconds: 240);

  final EarningsPeriod selectedPeriod;
  final ValueChanged<EarningsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _animationDuration;
    final alignmentX = switch (selectedPeriod) {
      EarningsPeriod.daily => -1.0,
      EarningsPeriod.weekly => 0.0,
      EarningsPeriod.monthly => 1.0,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              for (final period in EarningsPeriod.values)
                Expanded(
                  child: _PeriodTab(
                    period: period,
                    isSelected: period == selectedPeriod,
                    animationDuration: animationDuration,
                    onTap: () => onSelected(period),
                  ),
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 2,
            child: IgnorePointer(
              child: AnimatedAlign(
                key: const ValueKey<String>('driver-earnings-period-indicator'),
                alignment: Alignment(alignmentX, 0),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / EarningsPeriod.values.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _PeriodTab({
  required this.period,
  required this.isSelected,
  required this.animationDuration,
  required this.onTap,
}) extends StatelessWidget {
  final EarningsPeriod period;
  final bool isSelected;
  final Duration animationDuration;
  final VoidCallback onTap;

  String get _label => switch (period) {
    EarningsPeriod.daily => 'Day',
    EarningsPeriod.weekly => 'Week',
    EarningsPeriod.monthly => 'Month',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final labelStyle =
        (context.textStyles.labelLarge ?? const TextStyle(fontSize: 14))
            .copyWith(
              color: isSelected
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0,
            );

    return Semantics(
      button: true,
      selected: isSelected,
      label: _label,
      child: InkWell(
        key: ValueKey<String>('driver-earnings-period-${period.name}'),
        onTap: onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sm),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 10),
              child: AnimatedDefaultTextStyle(
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                style: labelStyle,
                child: Text(_label, maxLines: 1, overflow: TextOverflow.fade),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

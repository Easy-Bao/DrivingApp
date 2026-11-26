import 'package:design_system/src/theme/quiet_button_style.dart';
import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

class const AppSegmentedTabOption<T>({
  required this.value,
  required this.label,
  this.keySuffix,
}) {
  final T value;
  final String label;
  final String? keySuffix;
}

/// Hairline underline-segmented tab bar shared across period and filter views.
class const AppSegmentedTabBar<T>({
  super.key,
  required this.options,
  required this.selectedValue,
  required this.onSelected,
  this.indicatorKey,
  this.itemKeyPrefix,
}) extends StatelessWidget {
  static const Duration _animationDuration = Duration(milliseconds: 240);

  final List<AppSegmentedTabOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final String? indicatorKey;
  final String? itemKeyPrefix;

  this : assert(options.length > 0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animationDuration = disableAnimations
        ? Duration.zero
        : _animationDuration;
    final selectedIndex = options.indexWhere(
      (option) => option.value == selectedValue,
    );
    final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final alignmentX = options.length == 1
        ? 0.0
        : -1.0 + (2.0 * safeIndex / (options.length - 1));

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
              for (var index = 0; index < options.length; index++)
                Expanded(
                  child: _AppSegmentedTabItem(
                    label: options[index].label,
                    isSelected: index == safeIndex,
                    animationDuration: animationDuration,
                    itemKey: itemKeyPrefix == null
                        ? null
                        : ValueKey<String>(
                            '$itemKeyPrefix-${options[index].keySuffix ?? index}',
                          ),
                    onTap: () => onSelected(options[index].value),
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
                key: indicatorKey == null
                    ? null
                    : ValueKey<String>(indicatorKey!),
                alignment: Alignment(alignmentX, 0),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / options.length,
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

class const _AppSegmentedTabItem({
  required this.label,
  required this.isSelected,
  required this.animationDuration,
  required this.onTap,
  this.itemKey,
}) extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Duration animationDuration;
  final VoidCallback onTap;
  final Key? itemKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final baseStyle =
        context.textStyles.labelLarge ?? Theme.of(context).textTheme.bodyMedium;
    final labelStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        key: itemKey,
        onTap: onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: AppQuietInteraction.focusOverlay(colorScheme.primary),
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
                child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

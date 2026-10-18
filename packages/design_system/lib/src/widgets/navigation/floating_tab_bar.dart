import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:design_system/src/widgets/navigation/swipe_tab_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef AppTabIconBuilder =
    Widget Function(
      BuildContext context,
      int index,
      AppTabDestination destination,
      Color color,
    );

class AppTabDestination {
  const AppTabDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Shared floating navigation surface used by both authenticated clients.
///
/// The tab bar owns the visual contract—slot sizing, active indicator
/// geometry, selected color interpolation, and touch semantics—while an app
/// may provide an icon builder for a destination-specific badge.
class AppFloatingTabBar extends StatelessWidget {
  const AppFloatingTabBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.itemKeyPrefix,
    required this.indicatorKey,
    this.pagePosition,
    this.iconBuilder,

    /// When true the widget renders only the inner tab-row content with no outer
    /// container decoration, border, or shadow. Use when a parent supplies the
    /// shared surface (e.g. a merged active-ride + tab bar layout).
    this.bare = false,
  }) : assert(destinations.length > 0);

  static const animationDuration = Duration(milliseconds: 280);
  static const height = EasyRideSize.navigationBarHeight;

  final List<AppTabDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueListenable<double>? pagePosition;
  final AppTabIconBuilder? iconBuilder;
  final String itemKeyPrefix;
  final String indicatorKey;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final activeIndex = selectedIndex.clamp(0, destinations.length - 1).toInt();

    final positionListenable = pagePosition;
    if (positionListenable != null) {
      return ValueListenableBuilder<double>(
        valueListenable: positionListenable,
        builder: (context, position, child) => _buildBar(
          context,
          activeIndex: activeIndex,
          pagePosition: position,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(end: activeIndex.toDouble()),
      builder: (context, position, child) =>
          _buildBar(context, activeIndex: activeIndex, pagePosition: position),
    );
  }

  Widget _buildBar(
    BuildContext context, {
    required int activeIndex,
    required double pagePosition,
  }) {
    final colorScheme = context.colorScheme;
    final visualPagePosition = pagePosition
        .clamp(0.0, (destinations.length - 1).toDouble())
        .toDouble();

    final inner = SizedBox(
      height: height,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: SwipeActiveTabIndicator(
                key: ValueKey<String>(indicatorKey),
                pagePosition: visualPagePosition,
                itemCount: destinations.length,
                color: colorScheme.surfaceContainerHighest,
              ),
            ),
            Row(
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Expanded(
                    child: _AppFloatingTabItem(
                      destination: destinations[index],
                      index: index,
                      isSelected: index == activeIndex,
                      pagePosition: visualPagePosition,
                      itemKeyPrefix: itemKeyPrefix,
                      iconBuilder: iconBuilder,
                      onTap: onDestinationSelected,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (bare) return inner;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.pill),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: inner,
    );
  }
}

class _AppFloatingTabItem extends StatelessWidget {
  const _AppFloatingTabItem({
    required this.destination,
    required this.index,
    required this.isSelected,
    required this.pagePosition,
    required this.itemKeyPrefix,
    required this.iconBuilder,
    required this.onTap,
  });

  final AppTabDestination destination;
  final int index;
  final bool isSelected;
  final double pagePosition;
  final String itemKeyPrefix;
  final AppTabIconBuilder? iconBuilder;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final selectionProgress = SwipeActiveTabIndicator.selectionProgress(
      pagePosition,
      index,
    );
    final targetColor =
        Color.lerp(
          colorScheme.onSurfaceVariant,
          colorScheme.primary,
          selectionProgress,
        ) ??
        colorScheme.onSurfaceVariant;
    final labelStyle = Theme.of(context).textTheme.labelMedium!;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          key: ValueKey<String>('$itemKeyPrefix-$index'),
          borderRadius: BorderRadius.circular(EasyRideRadius.pill),
          overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return colorScheme.surface.withValues(alpha: 0);
          }),
          onTap: () => onTap(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconBuilder?.call(context, index, destination, targetColor) ??
                    Icon(
                      destination.icon,
                      size: EasyRideSize.navigationIcon,
                      color: targetColor,
                    ),
                const SizedBox(height: EasyRideSpacing.sm / 2),
                Flexible(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    textScaler: MediaQuery.textScalerOf(context).clamp(
                      maxScaleFactor: 1.2,
                    ),
                    style: labelStyle.copyWith(
                      color: targetColor,
                      fontWeight: FontWeight.w500,
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
}

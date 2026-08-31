import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:design_system/src/theme/app_design_tokens.dart';
import 'package:design_system/src/theme/design_system_context.dart';
import 'package:design_system/src/widgets/swipe_active_tab_indicator.dart';

typedef AppTabIconBuilder =
    Widget Function(
      BuildContext context,
      int index,
      AppTabDestination destination,
      Color color,
    );

class AppTabDestination {
  final IconData icon;
  final String label;

  const AppTabDestination({required this.icon, required this.label});
}

/// Shared floating navigation surface used by both authenticated clients.
///
/// The tab bar owns the visual contract—slot sizing, active indicator
/// geometry, selected color interpolation, and touch semantics—while an app
/// may provide an icon builder for a destination-specific badge.
class AppFloatingTabBar extends StatelessWidget {
  static const animationDuration = Duration(milliseconds: 280);
  static const height = AppDesignTokens.navigationBarHeight;

  final List<AppTabDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueListenable<double>? pagePosition;
  final AppTabIconBuilder? iconBuilder;
  final String itemKeyPrefix;
  final String indicatorKey;

  const AppFloatingTabBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.itemKeyPrefix,
    required this.indicatorKey,
    this.pagePosition,
    this.iconBuilder,
  }) : assert(destinations.length > 0);

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

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.pillRadius),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                capsuleKeyPrefix: indicatorKey,
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
  }
}

class _AppFloatingTabItem extends StatelessWidget {
  final AppTabDestination destination;
  final int index;
  final bool isSelected;
  final double pagePosition;
  final String itemKeyPrefix;
  final AppTabIconBuilder? iconBuilder;
  final ValueChanged<int> onTap;

  const _AppFloatingTabItem({
    required this.destination,
    required this.index,
    required this.isSelected,
    required this.pagePosition,
    required this.itemKeyPrefix,
    required this.iconBuilder,
    required this.onTap,
  });

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
    final labelStyle = Theme.of(context).textTheme.labelSmall!;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          key: ValueKey<String>('$itemKeyPrefix-$index'),
          borderRadius: BorderRadius.circular(AppDesignTokens.pillRadius),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(
            colorScheme.surface.withValues(alpha: 0),
          ),
          onTap: () => onTap(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconBuilder?.call(context, index, destination, targetColor) ??
                    Icon(
                      destination.icon,
                      size: AppDesignTokens.navigationIconSize,
                      color: targetColor,
                    ),
                const SizedBox(height: AppDesignTokens.compactGap / 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: labelStyle.copyWith(
                    color: targetColor,
                    fontSize: AppDesignTokens.navigationLabelSize,
                    fontWeight: FontWeight.w500,
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

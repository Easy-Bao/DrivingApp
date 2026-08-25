import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverFloatingTabBar extends StatelessWidget {
  static const animationDuration = Duration(milliseconds: 280);
  static const height = 60.0;

  static const _destinations = <_DriverTabDestination>[
    _DriverTabDestination(
      icon: LucideIcons.layout_dashboard,
      label: 'Dashboard',
    ),
    _DriverTabDestination(icon: LucideIcons.history, label: 'Trips'),
    _DriverTabDestination(icon: LucideIcons.wallet, label: 'Earnings'),
    _DriverTabDestination(icon: LucideIcons.user, label: 'Account'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueListenable<double>? pagePosition;

  const DriverFloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.pagePosition,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex = selectedIndex
        .clamp(0, _destinations.length - 1)
        .toInt();

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
    final visualPagePosition = pagePosition
        .clamp(0.0, (_destinations.length - 1).toDouble())
        .toDouble();

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.outlineBorderColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: SwipeActiveTabIndicator(
                    key: const ValueKey<String>(
                      'driver-floating-tab-indicator',
                    ),
                    pagePosition: visualPagePosition,
                    itemCount: _destinations.length,
                    color: AppTheme.neutralColor,
                    capsuleKeyPrefix: 'driver-floating-tab-indicator',
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < _destinations.length; index++)
                      Expanded(
                        child: _DriverFloatingTabItem(
                          destination: _destinations[index],
                          index: index,
                          isSelected: index == activeIndex,
                          pagePosition: visualPagePosition,
                          onTap: onDestinationSelected,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DriverFloatingTabItem extends StatelessWidget {
  final _DriverTabDestination destination;
  final int index;
  final bool isSelected;
  final double pagePosition;
  final ValueChanged<int> onTap;

  const _DriverFloatingTabItem({
    required this.destination,
    required this.index,
    required this.isSelected,
    required this.pagePosition,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectionProgress = SwipeActiveTabIndicator.selectionProgress(
      pagePosition,
      index,
    );
    final targetColor =
        Color.lerp(
          AppTheme.unselectedItemColor,
          AppTheme.selectedItemColor,
          selectionProgress,
        ) ??
        AppTheme.unselectedItemColor;
    final labelStyle = Theme.of(context).textTheme.labelSmall!;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          key: ValueKey<String>('driver-floating-tab-item-$index'),
          borderRadius: BorderRadius.circular(27),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(
            AppTheme.surface.withValues(alpha: 0),
          ),
          onTap: () => onTap(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(destination.icon, size: 18, color: targetColor),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: labelStyle.copyWith(
                    color: targetColor,
                    fontSize: 10,
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

class _DriverTabDestination {
  final IconData icon;
  final String label;

  const _DriverTabDestination({required this.icon, required this.label});
}

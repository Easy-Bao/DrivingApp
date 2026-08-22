import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class DriverFloatingTabBar extends StatelessWidget {
  static const animationDuration = Duration(milliseconds: 320);

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

  const DriverFloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex = selectedIndex.clamp(0, _destinations.length - 1);

    return Container(
      height: 68,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: AppTheme.outlineBorderColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final destinationWidth =
                constraints.maxWidth / _destinations.length;

            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: animationDuration,
                  curve: Curves.easeOutCubic,
                  top: 4,
                  bottom: 4,
                  start: destinationWidth * activeIndex + 4,
                  width: destinationWidth - 8,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey<String>(
                        'driver-floating-tab-indicator',
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
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
  final ValueChanged<int> onTap;

  const _DriverFloatingTabItem({
    required this.destination,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final targetColor = isSelected
        ? AppTheme.selectedItemColor
        : AppTheme.unselectedItemColor;
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
          borderRadius: BorderRadius.circular(30),
          onTap: () => onTap(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: DriverFloatingTabBar.animationDuration,
                  curve: Curves.easeOutCubic,
                  scale: isSelected ? 1.12 : 1,
                  child: TweenAnimationBuilder<Color?>(
                    duration: DriverFloatingTabBar.animationDuration,
                    curve: Curves.easeOutCubic,
                    tween: ColorTween(end: targetColor),
                    builder: (context, color, child) => Icon(
                      destination.icon,
                      size: 20,
                      color: color ?? targetColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: DriverFloatingTabBar.animationDuration,
                  curve: Curves.easeOutCubic,
                  style: labelStyle.copyWith(
                    color: targetColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
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

import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class DriverFloatingTabBar extends StatelessWidget {
  static const animationDuration = Duration(milliseconds: 320);
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

  const DriverFloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex = selectedIndex.clamp(0, _destinations.length - 1);

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
            final destinationWidth =
                constraints.maxWidth / _destinations.length;

            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: animationDuration,
                  curve: Curves.easeOutCubic,
                  top: 3,
                  bottom: 3,
                  start: destinationWidth * activeIndex + 3,
                  width: destinationWidth - 6,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey<String>(
                        'driver-floating-tab-indicator',
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(27),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/design_system.dart';

class const DriverBottomNavigation({
  super.key,
  required this.selectedIndex,
  required this.onDestinationSelected,
  this.pagePosition,
}) extends StatelessWidget {
  static const animationDuration = AppFloatingTabBar.animationDuration;
  static const height = AppFloatingTabBar.height;

  static const destinations = <AppTabDestination>[
    AppTabDestination(icon: LucideIcons.layout_dashboard, label: 'Dashboard'),
    AppTabDestination(icon: LucideIcons.history, label: 'Trips'),
    AppTabDestination(icon: LucideIcons.wallet, label: 'Earnings'),
    AppTabDestination(icon: LucideIcons.user, label: 'Account'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueListenable<double>? pagePosition;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          top: false,
          child: AppFloatingTabBar(
            bare: true,
            showInteractionFeedback: false,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            pagePosition: pagePosition,
            destinations: destinations,
            itemKeyPrefix: 'driver-tab-item',
            indicatorKey: 'driver-tab-indicator',
          ),
        ),
      ),
    );
  }
}

class const ShellNavigationRail({
  super.key,
  required this.selectedIndex,
  required this.onDestinationSelected,
}) extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return AppNavigationRail(
      destinations: DriverBottomNavigation.destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}

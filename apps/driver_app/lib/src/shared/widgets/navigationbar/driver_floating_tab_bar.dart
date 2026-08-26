import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverFloatingTabBar extends StatelessWidget {
  static const animationDuration = AppFloatingTabBar.animationDuration;
  static const height = AppFloatingTabBar.height;

  static const _destinations = <AppTabDestination>[
    AppTabDestination(icon: LucideIcons.layout_dashboard, label: 'Dashboard'),
    AppTabDestination(icon: LucideIcons.history, label: 'Trips'),
    AppTabDestination(icon: LucideIcons.wallet, label: 'Earnings'),
    AppTabDestination(icon: LucideIcons.user, label: 'Account'),
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
    return AppFloatingTabBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      pagePosition: pagePosition,
      destinations: _destinations,
      itemKeyPrefix: 'driver-floating-tab-item',
      indicatorKey: 'driver-floating-tab-indicator',
    );
  }
}

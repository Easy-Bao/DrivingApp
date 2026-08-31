import 'package:driver_app/src/app/navigation/driver_floating_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

typedef DriverTabNavigationCoordinator = TabNavigationCoordinator;

class DriverTabBranchContainer extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final ValueChanged<int> onNavigationSettled;
  final ValueChanged<double> onPagePositionChanged;

  const DriverTabBranchContainer({
    super.key,
    required this.navigationShell,
    required this.children,
    required this.onNavigationSettled,
    required this.onPagePositionChanged,
  });

  @override
  Widget build(BuildContext context) => AppTabBranchContainer(
    key: key,
    currentIndex: navigationShell.currentIndex,
    onBranchChanged: (index) => navigationShell.goBranch(index),
    onNavigationSettled: onNavigationSettled,
    onPagePositionChanged: onPagePositionChanged,
    backgroundColor: context.canvasColor,
    pageViewKey: 'driver-tab-page-view',
    children: children,
  );
}

class DriverShellLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final DriverTabNavigationCoordinator navigationCoordinator;

  const DriverShellLayout({
    super.key,
    required this.navigationShell,
    required this.navigationCoordinator,
  });

  @override
  State<DriverShellLayout> createState() => _DriverShellLayoutState();
}

class _DriverShellLayoutState extends State<DriverShellLayout> {
  @override
  void initState() {
    super.initState();
    widget.navigationCoordinator.initialize(
      widget.navigationShell.currentIndex,
    );
    widget.navigationCoordinator.addListener(_onNavigationChanged);
  }

  @override
  void dispose() {
    widget.navigationCoordinator.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navigationCoordinator.selectedIndex;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: widget.navigationCoordinator.canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final previousIndex = widget.navigationCoordinator
            .goBackToPreviousTab();
        widget.navigationShell.goBranch(previousIndex);
      },
      child: Scaffold(
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding + 10),
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DriverFloatingTabBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: _onItemTapped,
                pagePosition: widget.navigationCoordinator.pagePosition,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (widget.navigationCoordinator.selectedIndex == index) return;
    widget.navigationCoordinator.commit(index);
    widget.navigationShell.goBranch(index);
  }
}

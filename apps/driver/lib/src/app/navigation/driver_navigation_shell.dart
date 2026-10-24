import 'package:driver/src/app/navigation/driver_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class const TabBranchContainer({
  super.key,
  required this.navigationShell,
  required this.children,
  required this.onNavigationSettled,
  required this.onPagePositionChanged,
}) extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final ValueChanged<int> onNavigationSettled;
  final ValueChanged<double> onPagePositionChanged;

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

class const ShellLayout({
  super.key,
  required this.navigationShell,
  required this.navigationCoordinator,
}) extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final TabNavigationCoordinator navigationCoordinator;

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
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
    final isWide = MediaQuery.sizeOf(context).width >= AppLayout.wideBreakpoint;

    return PopScope(
      canPop: widget.navigationCoordinator.canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final previousIndex = widget.navigationCoordinator
            .goBackToPreviousTab();
        widget.navigationShell.goBranch(previousIndex);
      },
      child: Scaffold(
        extendBody: false,
        body: isWide
            ? Row(
                children: [
                  ShellNavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: _onItemTapped,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: widget.navigationShell),
                ],
              )
            : widget.navigationShell,
        bottomNavigationBar: isWide
            ? const SizedBox.shrink()
            : DriverBottomNavigation(
                selectedIndex: selectedIndex,
                onDestinationSelected: _onItemTapped,
                pagePosition: widget.navigationCoordinator.pagePosition,
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

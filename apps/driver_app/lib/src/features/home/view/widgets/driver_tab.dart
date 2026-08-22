import 'dart:async';

import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/home/view/widgets/driver_floating_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DriverTabNavigationCoordinator extends ChangeNotifier {
  int? _selectedIndex;
  final List<int> _navigationHistory = [];

  int get selectedIndex => _selectedIndex ?? 0;

  bool get canPop =>
      _navigationHistory.length <= 1 &&
      _navigationHistory.isNotEmpty &&
      _navigationHistory.last == 0;

  void initialize(int index) {
    if (_selectedIndex != null) return;
    _selectedIndex = index;
    _navigationHistory.add(index);
  }

  void commit(int index) {
    if (_selectedIndex == null) {
      initialize(index);
      notifyListeners();
      return;
    }
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    _navigationHistory.add(index);
    notifyListeners();
  }

  int goBackToPreviousTab() {
    if (_navigationHistory.length > 1) {
      _navigationHistory.removeLast();
      _selectedIndex = _navigationHistory.last;
    } else {
      _navigationHistory
        ..clear()
        ..add(0);
      _selectedIndex = 0;
    }
    notifyListeners();
    return selectedIndex;
  }
}

class DriverTabBranchContainer extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final ValueChanged<int> onNavigationSettled;

  const DriverTabBranchContainer({
    super.key,
    required this.navigationShell,
    required this.children,
    required this.onNavigationSettled,
  });

  @override
  State<DriverTabBranchContainer> createState() =>
      _DriverTabBranchContainerState();
}

class _DriverTabBranchContainerState extends State<DriverTabBranchContainer> {
  static const _pageAnimationDuration = Duration(milliseconds: 280);

  late final PageController _pageController;
  int _activeIndex = 0;
  int? _gestureStartIndex;
  int? _previewIndex;
  bool _isUserDragging = false;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.navigationShell.currentIndex;
    _pageController = PageController(initialPage: _activeIndex);
  }

  @override
  void didUpdateWidget(covariant DriverTabBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = widget.navigationShell.currentIndex;
    if (_isUserDragging || targetIndex == _activeIndex) return;

    _activeIndex = targetIndex;
    widget.onNavigationSettled(targetIndex);
    _animateToPage(targetIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.background,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: PageView(
          key: const ValueKey<String>('driver-tab-page-view'),
          controller: _pageController,
          allowImplicitScrolling: true,
          children: widget.children,
          onPageChanged: (index) {
            if (_isUserDragging) return;
            _activeIndex = index;
            widget.onNavigationSettled(index);
          },
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _isUserDragging = true;
      _gestureStartIndex = _activeIndex;
      _previewIndex = null;
      return false;
    }

    if (notification is ScrollUpdateNotification && _isUserDragging) {
      _preloadAdjacentBranch();
      return false;
    }

    if (notification is ScrollEndNotification && _isUserDragging) {
      _finishUserDrag();
      return false;
    }

    return false;
  }

  void _preloadAdjacentBranch() {
    final startIndex = _gestureStartIndex;
    final page = _pageController.hasClients ? _pageController.page : null;
    if (startIndex == null || page == null) return;

    final movement = page - startIndex;
    if (movement.abs() < 0.01) return;

    final adjacentIndex = startIndex + (movement > 0 ? 1 : -1);
    if (adjacentIndex < 0 || adjacentIndex >= widget.children.length) return;
    if (_previewIndex == adjacentIndex) return;

    _previewIndex = adjacentIndex;
    widget.navigationShell.goBranch(adjacentIndex);
  }

  void _finishUserDrag() {
    final settledIndex =
        (_pageController.hasClients
                ? (_pageController.page ?? _activeIndex)
                : _activeIndex.toDouble())
            .round()
            .clamp(0, widget.children.length - 1);

    _isUserDragging = false;
    _gestureStartIndex = null;
    _previewIndex = null;
    _activeIndex = settledIndex;
    widget.navigationShell.goBranch(settledIndex);
    widget.onNavigationSettled(settledIndex);
  }

  void _animateToPage(int index) {
    if (!_pageController.hasClients) return;
    if (_pageController.page?.round() == index) return;
    unawaited(
      _pageController.animateToPage(
        index,
        duration: _pageAnimationDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }
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

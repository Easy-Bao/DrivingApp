import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps a tab page view and its navigation state synchronized during taps,
/// programmatic changes, and interactive swipes.
///
/// The route shell stays outside this module. Callers provide the current
/// route index and a branch callback, while this implementation owns the
/// gesture lifecycle and continuously reports the page position used by the
/// active-tab indicator.
class const AppTabBranchContainer({
  super.key,
  required this.currentIndex,
  required this.children,
  required this.onBranchChanged,
  required this.onNavigationSettled,
  required this.onPagePositionChanged,
  required this.backgroundColor,
  required this.pageViewKey,
}) extends StatefulWidget {
  static const pageAnimationDuration = Duration(milliseconds: 280);

  final int currentIndex;
  final List<Widget> children;
  final ValueChanged<int> onBranchChanged;
  final ValueChanged<int> onNavigationSettled;
  final ValueChanged<double> onPagePositionChanged;
  final Color backgroundColor;
  final String pageViewKey;

  this : assert(children.length > 0);

  @override
  State<AppTabBranchContainer> createState() => _AppTabBranchContainerState();
}

class _AppTabBranchContainerState extends State<AppTabBranchContainer> {
  late final PageController _pageController;
  int _activeIndex = 0;
  int? _gestureStartIndex;
  int? _previewIndex;
  bool _isUserDragging = false;

  @override
  void initState() {
    super.initState();
    _activeIndex = _safeIndex(widget.currentIndex);
    _pageController = PageController(initialPage: _activeIndex);
    _pageController.addListener(_handlePagePositionChanged);
    widget.onPagePositionChanged(_activeIndex.toDouble());
  }

  @override
  void didUpdateWidget(covariant AppTabBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _safeIndex(widget.currentIndex);
    if (_isUserDragging || targetIndex == _activeIndex) return;

    _activeIndex = targetIndex;
    _settleExternalNavigation(targetIndex);
    _animateToPage(targetIndex);
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePagePositionChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: PageView(
          key: ValueKey<String>(widget.pageViewKey),
          controller: _pageController,
          allowImplicitScrolling: true,
          children: widget.children,
          onPageChanged: (index) {
            if (_isUserDragging || index != widget.currentIndex) return;
            _activeIndex = index;
            widget.onNavigationSettled(index);
          },
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Child lists also bubble scroll notifications through PageView. Only
    // depth-zero notifications represent the tab page gesture itself.
    if (notification.depth != 0) return false;

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

  void _handlePagePositionChanged() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null || !page.isFinite) return;
    widget.onPagePositionChanged(page);
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
    widget.onBranchChanged(adjacentIndex);
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
    widget.onBranchChanged(settledIndex);
    widget.onNavigationSettled(settledIndex);
  }

  void _settleExternalNavigation(int targetIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _safeIndex(widget.currentIndex) != targetIndex) return;
      widget.onNavigationSettled(targetIndex);
    });
  }

  void _animateToPage(int index) {
    if (!_pageController.hasClients) return;
    if (_pageController.page?.round() == index) return;
    unawaited(
      _pageController.animateToPage(
        index,
        duration: AppTabBranchContainer.pageAnimationDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  int _safeIndex(int index) =>
      index.clamp(0, widget.children.length - 1).toInt();
}

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/inbox/presentation/formatters/inbox_presenter.dart';

class InboxFilterBar extends StatefulWidget {
  const InboxFilterBar({
    super.key,
    required this.selectedFilter,
    required this.unreadCount,
    required this.onSelected,
  });

  final InboxFilter selectedFilter;
  final int unreadCount;
  final ValueChanged<InboxFilter> onSelected;

  @override
  State<InboxFilterBar> createState() => _InboxFilterBarState();
}

class _InboxFilterBarState extends State<InboxFilterBar> {
  static const Duration _animationDuration = Duration(milliseconds: 260);

  final GlobalKey _rowKey = GlobalKey();
  final Map<InboxFilter, GlobalKey> _tabKeys = <InboxFilter, GlobalKey>{
    for (final filter in InboxFilter.values) filter: GlobalKey(),
  };

  double? _indicatorLeft;
  double? _indicatorWidth;
  bool _measurementScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleIndicatorMeasure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleIndicatorMeasure();
  }

  @override
  void didUpdateWidget(covariant InboxFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter) {
      _updateIndicatorBounds(notify: false);
      _scheduleIndicatorMeasure();
      _scrollSelectedTabIntoView();
    } else if (oldWidget.unreadCount != widget.unreadCount) {
      _scheduleIndicatorMeasure();
    }
  }

  void _scheduleIndicatorMeasure() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;
      _updateIndicatorBounds(notify: true);
    });
  }

  void _updateIndicatorBounds({required bool notify}) {
    final rowObject = _rowKey.currentContext?.findRenderObject();
    final tabObject = _tabKeys[widget.selectedFilter]?.currentContext
        ?.findRenderObject();
    if (rowObject is! RenderBox ||
        tabObject is! RenderBox ||
        !rowObject.hasSize ||
        !tabObject.hasSize) {
      return;
    }

    final offset = tabObject.localToGlobal(Offset.zero, ancestor: rowObject);
    final left = offset.dx;
    final width = tabObject.size.width;
    if (_indicatorLeft == left && _indicatorWidth == width) return;

    if (notify) {
      setState(() {
        _indicatorLeft = left;
        _indicatorWidth = width;
      });
    } else {
      _indicatorLeft = left;
      _indicatorWidth = width;
    }
  }

  void _scrollSelectedTabIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabContext = _tabKeys[widget.selectedFilter]?.currentContext;
      if (tabContext == null) return;
      final duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : _animationDuration;
      unawaited(
        Scrollable.ensureVisible(
          tabContext,
          duration: duration,
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _animationDuration;
    final hasMeasuredIndicator =
        _indicatorLeft != null && _indicatorWidth != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              key: _rowKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final filter in InboxFilter.values) ...[
                  KeyedSubtree(
                    key: _tabKeys[filter],
                    child: _InboxFilterTab(
                      filter: filter,
                      isSelected: filter == widget.selectedFilter,
                      showFallbackIndicator: !hasMeasuredIndicator,
                      animationDuration: animationDuration,
                      count: filter == InboxFilter.unread
                          ? widget.unreadCount
                          : null,
                      onTap: () => widget.onSelected(filter),
                    ),
                  ),
                  if (filter != InboxFilter.values.last)
                    const SizedBox(width: AppSpacing.xl),
                ],
              ],
            ),
            if (hasMeasuredIndicator)
              AnimatedPositioned(
                key: const ValueKey<String>('inbox-filter-indicator'),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                left: _indicatorLeft!,
                width: _indicatorWidth!,
                bottom: 0,
                height: 2,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InboxFilterTab extends StatelessWidget {
  const _InboxFilterTab({
    required this.filter,
    required this.isSelected,
    required this.showFallbackIndicator,
    required this.animationDuration,
    required this.onTap,
    this.count,
  });

  final InboxFilter filter;
  final bool isSelected;
  final bool showFallbackIndicator;
  final Duration animationDuration;
  final int? count;
  final VoidCallback onTap;

  String get _label => switch (filter) {
    InboxFilter.all => 'All',
    InboxFilter.unread => 'Unread',
    InboxFilter.messages => 'Messages',
    InboxFilter.rides => 'Rides',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final badgeCount = count;
    final showCount = badgeCount != null && badgeCount > 0;
    final semanticLabel = showCount ? '$_label, $badgeCount' : _label;
    final labelStyle = (textStyles.labelLarge ?? defaultStyle).copyWith(
      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0,
    );
    final countStyle = (textStyles.labelSmall ?? defaultStyle).tabular.copyWith(
      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      child: InkWell(
        key: ValueKey<String>('inbox-filter-${filter.name}'),
        onTap: onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sm),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget,
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: animationDuration,
                        curve: Curves.easeOutCubic,
                        style: labelStyle,
                        child: Text(_label),
                      ),
                      if (showCount) ...[
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: animationDuration,
                          curve: Curves.easeOutCubic,
                          style: countStyle,
                          child: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: 2,
                  child: showFallbackIndicator && isSelected
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

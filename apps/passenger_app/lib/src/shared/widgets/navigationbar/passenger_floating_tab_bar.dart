import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_state.dart';
import 'package:shared_ui/shared_ui.dart';

class PassengerFloatingTabBar extends StatelessWidget {
  static const animationDuration = Duration(milliseconds: 280);
  static const height = 60.0;

  static const _destinations = <_PassengerTabDestination>[
    _PassengerTabDestination(icon: LucideIcons.house, label: 'Home'),
    _PassengerTabDestination(icon: LucideIcons.history, label: 'Activity'),
    _PassengerTabDestination(icon: LucideIcons.mail, label: 'Inbox'),
    _PassengerTabDestination(icon: LucideIcons.user, label: 'Profile'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final InboxCubit inboxCubit;
  final ValueListenable<double>? pagePosition;

  const PassengerFloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.inboxCubit,
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
                      'passenger-floating-tab-indicator',
                    ),
                    pagePosition: visualPagePosition,
                    itemCount: _destinations.length,
                    color: AppTheme.neutralColor,
                    capsuleKeyPrefix: 'passenger-floating-tab-indicator',
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < _destinations.length; index++)
                      Expanded(
                        child: _PassengerFloatingTabItem(
                          destination: _destinations[index],
                          index: index,
                          isSelected: index == activeIndex,
                          pagePosition: visualPagePosition,
                          inboxCubit: inboxCubit,
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

class _PassengerFloatingTabItem extends StatelessWidget {
  final _PassengerTabDestination destination;
  final int index;
  final bool isSelected;
  final double pagePosition;
  final InboxCubit inboxCubit;
  final ValueChanged<int> onTap;

  const _PassengerFloatingTabItem({
    required this.destination,
    required this.index,
    required this.isSelected,
    required this.pagePosition,
    required this.inboxCubit,
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
          key: ValueKey<String>('passenger-floating-tab-item-$index'),
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
                if (index == 2)
                  _InboxTabIcon(color: targetColor, inboxCubit: inboxCubit)
                else
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

class _InboxTabIcon extends StatelessWidget {
  final Color color;
  final InboxCubit inboxCubit;

  const _InboxTabIcon({required this.color, required this.inboxCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxCubit, InboxState>(
      bloc: inboxCubit,
      builder: (context, state) {
        final unreadCount = state is InboxLoadedState
            ? state.notifications
                  .where((notification) => !notification.isRead)
                  .length
            : 0;

        return SizedBox(
          width: 26,
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(LucideIcons.mail, size: 18, color: color),
              if (unreadCount > 0)
                Positioned(
                  top: -8,
                  right: -5,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppTheme.cancel,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: AppTheme.surface,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PassengerTabDestination {
  final IconData icon;
  final String label;

  const _PassengerTabDestination({required this.icon, required this.label});
}

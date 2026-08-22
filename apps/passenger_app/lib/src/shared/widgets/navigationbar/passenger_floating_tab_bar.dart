import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_state.dart';

class PassengerFloatingTabBar extends StatelessWidget {
  static const animationDuration = Duration(milliseconds: 320);

  static const _destinations = <_PassengerTabDestination>[
    _PassengerTabDestination(icon: LucideIcons.house, label: 'Home'),
    _PassengerTabDestination(icon: LucideIcons.history, label: 'Activity'),
    _PassengerTabDestination(icon: LucideIcons.mail, label: 'Inbox'),
    _PassengerTabDestination(icon: LucideIcons.user, label: 'Profile'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final InboxCubit inboxCubit;

  const PassengerFloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.inboxCubit,
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
                        'passenger-floating-tab-indicator',
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
                        child: _PassengerFloatingTabItem(
                          destination: _destinations[index],
                          index: index,
                          isSelected: index == activeIndex,
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
  final InboxCubit inboxCubit;
  final ValueChanged<int> onTap;

  const _PassengerFloatingTabItem({
    required this.destination,
    required this.index,
    required this.isSelected,
    required this.inboxCubit,
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
          key: ValueKey<String>('passenger-floating-tab-item-$index'),
          borderRadius: BorderRadius.circular(30),
          onTap: () => onTap(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: PassengerFloatingTabBar.animationDuration,
                  curve: Curves.easeOutCubic,
                  scale: isSelected ? 1.12 : 1,
                  child: TweenAnimationBuilder<Color?>(
                    duration: PassengerFloatingTabBar.animationDuration,
                    curve: Curves.easeOutCubic,
                    tween: ColorTween(end: targetColor),
                    builder: (context, color, child) {
                      if (index == 2) {
                        return _InboxTabIcon(
                          color: color ?? targetColor,
                          inboxCubit: inboxCubit,
                        );
                      }
                      return Icon(
                        destination.icon,
                        size: 20,
                        color: color ?? targetColor,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: PassengerFloatingTabBar.animationDuration,
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
          width: 28,
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(LucideIcons.mail, size: 20, color: color),
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

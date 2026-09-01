import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox/inbox_state.dart';
import 'package:design_system/design_system.dart';

class const PassengerFloatingTabBar({
  super.key,
  required this.selectedIndex,
  required this.onDestinationSelected,
  required this.inboxCubit,
  this.pagePosition,
}) extends StatelessWidget {
  static const animationDuration = AppFloatingTabBar.animationDuration;
  static const height = AppFloatingTabBar.height;

  static const _destinations = <AppTabDestination>[
    AppTabDestination(icon: LucideIcons.house, label: 'Home'),
    AppTabDestination(icon: LucideIcons.history, label: 'Activity'),
    AppTabDestination(icon: LucideIcons.mail, label: 'Inbox'),
    AppTabDestination(icon: LucideIcons.user, label: 'Profile'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final InboxCubit inboxCubit;
  final ValueListenable<double>? pagePosition;

  @override
  Widget build(BuildContext context) {
    return AppFloatingTabBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      pagePosition: pagePosition,
      destinations: _destinations,
      itemKeyPrefix: 'passenger-floating-tab-item',
      indicatorKey: 'passenger-floating-tab-indicator',
      iconBuilder: (context, index, destination, color) => index == 2
          ? _InboxTabIcon(color: color, inboxCubit: inboxCubit)
          : Icon(
              destination.icon,
              size: AppDesignTokens.navigationIconSize,
              color: color,
            ),
    );
  }
}

class const _InboxTabIcon({required this.color, required this.inboxCubit})
    extends StatelessWidget {
  final Color color;
  final InboxCubit inboxCubit;

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
              Icon(
                LucideIcons.mail,
                size: AppDesignTokens.navigationIconSize,
                color: color,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -8,
                  right: -5,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: context.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        color: context.colorScheme.surface,
                        fontSize: 11,
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

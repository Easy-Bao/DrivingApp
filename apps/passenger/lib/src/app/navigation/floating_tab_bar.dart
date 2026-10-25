import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';

class const FloatingTabBar({
  super.key,
  required this.selectedIndex,
  required this.onDestinationSelected,
  required this.inboxCubit,
  this.pagePosition,
  this.activeRideBanner,
}) extends StatelessWidget {
  static const animationDuration = AppFloatingTabBar.animationDuration;
  static const height = AppFloatingTabBar.height;

  static const destinations = <AppTabDestination>[
    AppTabDestination(icon: LucideIcons.house, label: 'Home'),
    AppTabDestination(icon: LucideIcons.history, label: 'Activity'),
    AppTabDestination(icon: LucideIcons.mail, label: 'Inbox'),
    AppTabDestination(icon: LucideIcons.user, label: 'Me'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final InboxCubit inboxCubit;
  final ValueListenable<double>? pagePosition;

  final Widget? activeRideBanner;

  @override
  Widget build(BuildContext context) {
    final banner = activeRideBanner;
    if (banner == null) {
      return AppFloatingTabBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        pagePosition: pagePosition,
        destinations: destinations,
        itemKeyPrefix: 'passenger-floating-tab-item',
        indicatorKey: 'passenger-floating-tab-indicator',
        iconBuilder: _buildIcon,
        showInteractionFeedback: false,
      );
    }

    final colorScheme = context.colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          banner,
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
          AppFloatingTabBar(
            bare: true,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            pagePosition: pagePosition,
            destinations: destinations,
            itemKeyPrefix: 'passenger-floating-tab-item',
            indicatorKey: 'passenger-floating-tab-indicator',
            iconBuilder: _buildIcon,
            showInteractionFeedback: false,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(
    BuildContext context,
    int index,
    AppTabDestination destination,
    Color color,
  ) => index == 2
      ? _InboxTabIcon(color: color, inboxCubit: inboxCubit)
      : Icon(destination.icon, size: AppSize.navigationIcon, color: color);
}

class const ShellNavigationRail({
  super.key,
  required this.selectedIndex,
  required this.onDestinationSelected,
  required this.inboxCubit,
}) extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final InboxCubit inboxCubit;

  @override
  Widget build(BuildContext context) {
    return AppNavigationRail(
      destinations: FloatingTabBar.destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      iconBuilder: (context, index, destination, color) => index == 2
          ? _InboxTabIcon(color: color, inboxCubit: inboxCubit)
          : Icon(destination.icon, size: AppSize.navigationIcon, color: color),
    );
  }
}

class const _InboxTabIcon({required this.color, required this.inboxCubit})
    extends StatelessWidget {
  final Color color;
  final InboxCubit inboxCubit;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<InboxCubit, InboxState, int>(
      bloc: inboxCubit,
      selector: (state) => state is InboxLoadedState
          ? state.notifications
                .where((notification) => !notification.isRead)
                .length
          : 0,
      builder: (context, unreadCount) {
        return SizedBox(
          width: 26,
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.mail,
                size: AppSize.navigationIcon,
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

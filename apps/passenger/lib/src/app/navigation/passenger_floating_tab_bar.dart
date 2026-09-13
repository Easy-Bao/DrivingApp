import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_state.dart';

class const PassengerFloatingTabBar({
  super.key,
  required this.selectedIndex,
  required this.onDestinationSelected,
  required this.inboxCubit,
  this.pagePosition,
}) extends StatelessWidget {
  static const animationDuration = AppFloatingTabBar.animationDuration;
  static const height = AppFloatingTabBar.height;

  static const destinations = <AppTabDestination>[
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
    if (!_supportsLiquidGlass) return _buildTabBar(context);

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildGlassBackdrop(context),
          OCLiquidGlassGroup(
            settings: const OCLiquidGlassSettings(
              refractStrength: -0.04,
              blurRadiusPx: 2.4,
              specStrength: 12,
              lightbandStrength: 0.65,
            ),
            child: OCLiquidGlass(
              width: double.infinity,
              height: height,
              borderRadius: EasyRideDesignTokens.pillRadius,
              color: context.colorScheme.surface.withValues(alpha: 0.56),
              child: _buildTabBar(context, transparentSurface: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBackdrop(BuildContext context) {
    final colorScheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideDesignTokens.pillRadius),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  bool get _supportsLiquidGlass =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Widget _buildTabBar(BuildContext context, {bool transparentSurface = false}) {
    return AppFloatingTabBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      pagePosition: pagePosition,
      destinations: destinations,
      transparentSurface: transparentSurface,
      itemKeyPrefix: 'passenger-floating-tab-item',
      indicatorKey: 'passenger-floating-tab-indicator',
      iconBuilder: (context, index, destination, color) => index == 2
          ? _InboxTabIcon(color: color, inboxCubit: inboxCubit)
          : Icon(
              destination.icon,
              size: EasyRideDesignTokens.navigationIconSize,
              color: color,
            ),
    );
  }
}

class const PassengerNavigationRail({
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
    return EasyRideNavigationRail(
      destinations: PassengerFloatingTabBar.destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      iconBuilder: (context, index, destination, color) => index == 2
          ? _InboxTabIcon(color: color, inboxCubit: inboxCubit)
          : Icon(
              destination.icon,
              size: EasyRideDesignTokens.navigationIconSize,
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
                size: EasyRideDesignTokens.navigationIconSize,
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

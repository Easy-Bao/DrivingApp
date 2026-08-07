import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_state.dart';
import 'package:passenger_app/src/features/inbox/inbox_routes.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/guest_action_bar_widget.dart';

class PassengerShellLayout extends StatefulWidget {
  final Widget child;
  final InboxCubit inboxCubit;

  const PassengerShellLayout({
    super.key,
    required this.child,
    required this.inboxCubit,
  });

  @override
  State<PassengerShellLayout> createState() => _PassengerShellLayoutState();
}

class _PassengerShellLayoutState extends State<PassengerShellLayout> {
  final List<int> _navigationHistory = [];
  String? _loadedInboxPassengerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadInboxNotifications());
      }
    });
  }

  Future<void> _loadInboxNotifications() async {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState is! AuthenticatedSession ||
        sessionState.passengerId == _loadedInboxPassengerId ||
        widget.inboxCubit.isClosed) {
      return;
    }
    _loadedInboxPassengerId = sessionState.passengerId;
    await widget.inboxCubit.loadNotifications(sessionState.passengerId);
  }

  @override
  Widget build(BuildContext context) {
    final sel = _calculateSelectedIndex(context);
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (_, current) =>
          current is AuthenticatedSession ||
          current is GuestSession ||
          current is SessionFailure,
      listener: (_, state) {
        switch (state) {
          case AuthenticatedSession():
            unawaited(_loadInboxNotifications());
          case GuestSession() || SessionFailure():
            _loadedInboxPassengerId = null;
            if (!widget.inboxCubit.isClosed) {
              widget.inboxCubit.clearSessionData();
            }
          case SessionLoading():
            break;
        }
      },
      child: PopScope(
        canPop:
            _navigationHistory.length <= 1 &&
            _navigationHistory.isNotEmpty &&
            _navigationHistory.last == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_navigationHistory.length > 1) {
            setState(() {
              _navigationHistory.removeLast();
              final previousIndex = _navigationHistory.last;
              _navigateToIndex(previousIndex);
            });
          } else {
            setState(() {
              _navigationHistory.clear();
              _navigationHistory.add(0);
              _navigateToIndex(0);
            });
          }
        },
        child: Scaffold(
          extendBody: true,
          body: widget.child,
          bottomNavigationBar: BlocBuilder<SessionBloc, SessionState>(
            builder: (context, sessionState) {
              final isAuthenticated = sessionState is AuthenticatedSession;
              if (!isAuthenticated) {
                return GuestActionBarWidget(
                  onSignUp: () => context.pushNamed(AuthRoutes.signup),
                  onSignIn: () => context.pushNamed(AuthRoutes.signin),
                  onHelp: () => context.pushNamed(ProfileRoutes.helpCenter),
                );
              }
              final bottomPadding = MediaQuery.of(context).padding.bottom;
              return Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 12),
                child: _buildAuthenticatedTabBar(context, sel),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedTabBar(BuildContext context, int selectedIndex) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(29),
        border: Border.all(
          color: AppTheme.outlineBorderColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(
            context,
            icon: LucideIcons.house,
            label: 'Home',
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          _buildTabItem(
            context,
            icon: LucideIcons.history,
            label: 'Activity',
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _buildTabItem(
            context,
            icon: LucideIcons.mail,
            label: 'Inbox',
            index: 2,
            isSelected: selectedIndex == 2,
          ),
          _buildTabItem(
            context,
            icon: LucideIcons.user,
            label: 'Profile',
            index: 3,
            isSelected: selectedIndex == 3,
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIndex = _calculateSelectedIndex(context);
    if (_navigationHistory.isEmpty) {
      _navigationHistory.add(newIndex);
    } else if (_navigationHistory.last != newIndex) {
      _navigationHistory.add(newIndex);
    }
  }

  Widget _buildTabItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final color = isSelected
        ? AppTheme.selectedItemColor
        : AppTheme.unselectedItemColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (index == 2)
                _InboxTabIcon(color: color, inboxCubit: widget.inboxCubit)
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String location = state.uri.path;
    final String? routeName = state.topRoute?.name;

    if (routeName != null) {
      if (routeName == HomeRoutes.home) {
        return 0;
      }
      if (routeName == ActivityRoutes.activity) {
        return 1;
      }
      if (routeName == InboxRoutes.inbox) {
        return 2;
      }
      if (routeName == ProfileRoutes.account ||
          routeName == ProfileRoutes.help) {
        return 3;
      }
    }

    if (location.startsWith(HomeRoutes.fullHomePath)) {
      return 0;
    }
    if (location.startsWith(ActivityRoutes.fullActivityPath)) {
      return 1;
    }
    if (location.startsWith(InboxRoutes.fullInboxPath)) {
      return 2;
    }
    if (location.startsWith(ProfileRoutes.fullAccountPath) ||
        location.startsWith(ProfileRoutes.fullHelpPath)) {
      return 3;
    }

    return 0;
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        context.goNamed(HomeRoutes.home);
        break;
      case 1:
        context.goNamed(ActivityRoutes.activity);
        break;
      case 2:
        context.goNamed(InboxRoutes.inbox);
        break;
      case 3:
        context.goNamed(ProfileRoutes.account);
        break;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _calculateSelectedIndex(context)) return;
    _navigateToIndex(index);
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
                        color: Colors.white,
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

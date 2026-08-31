import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/app/navigation/guest_action_bar.dart';
import 'package:passenger_app/src/app/navigation/passenger_floating_tab_bar.dart';
import 'package:shared_core/shared_core.dart';
import 'package:design_system/design_system.dart';

typedef PassengerTabNavigationCoordinator = TabNavigationCoordinator;

class PassengerTabBranchContainer extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final ValueChanged<int> onNavigationSettled;
  final ValueChanged<double> onPagePositionChanged;

  const PassengerTabBranchContainer({
    super.key,
    required this.navigationShell,
    required this.children,
    required this.onNavigationSettled,
    required this.onPagePositionChanged,
  });

  @override
  Widget build(BuildContext context) => AppTabBranchContainer(
    key: key,
    currentIndex: navigationShell.currentIndex,
    onBranchChanged: (index) => navigationShell.goBranch(index),
    onNavigationSettled: onNavigationSettled,
    onPagePositionChanged: onPagePositionChanged,
    backgroundColor: context.canvasColor,
    pageViewKey: 'passenger-tab-page-view',
    children: children,
  );
}

class PassengerShellLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final InboxCubit inboxCubit;
  final RealtimeWebSocketClient realtimeClient;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final PassengerTabNavigationCoordinator navigationCoordinator;

  const PassengerShellLayout({
    super.key,
    required this.navigationShell,
    required this.inboxCubit,
    required this.realtimeClient,
    required this.lifecycleCoordinator,
    required this.navigationCoordinator,
  });

  @override
  State<PassengerShellLayout> createState() => _PassengerShellLayoutState();
}

class _PassengerShellLayoutState extends State<PassengerShellLayout> {
  String? _loadedInboxPassengerId;
  String? _activePassengerId;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  late final StreamSubscription<AppLifecycleStatus> _lifecycleSubscription;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    _isForeground = widget.lifecycleCoordinator.isForeground;
    _lifecycleSubscription = widget.lifecycleCoordinator.changes.listen(
      _onLifecycleChanged,
    );
    widget.navigationCoordinator.initialize(
      widget.navigationShell.currentIndex,
    );
    widget.navigationCoordinator.addListener(_onNavigationChanged);
    _realtimeSubscription = widget.realtimeClient.events.listen(
      _handleRealtimeEvent,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadInboxNotifications());
      }
    });
  }

  @override
  void dispose() {
    widget.navigationCoordinator.removeListener(_onNavigationChanged);
    unawaited(_lifecycleSubscription.cancel());
    unawaited(_realtimeSubscription?.cancel());
    unawaited(widget.realtimeClient.stop());
    super.dispose();
  }

  void _onLifecycleChanged(AppLifecycleStatus status) {
    final isForeground = status == AppLifecycleStatus.foreground;
    if (!isForeground) {
      if (_isForeground) {
        _isForeground = false;
        unawaited(widget.realtimeClient.stop());
      }
      return;
    }

    if (_isForeground) return;
    _isForeground = true;
    if (_activePassengerId != null) {
      unawaited(widget.realtimeClient.start());
    }
  }

  void _onNavigationChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInboxNotifications() async {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState is! AuthenticatedSession || widget.inboxCubit.isClosed) {
      return;
    }
    _activePassengerId = sessionState.passengerId;
    if (_isForeground) {
      unawaited(widget.realtimeClient.start());
    }
    if (sessionState.passengerId == _loadedInboxPassengerId) return;
    _loadedInboxPassengerId = sessionState.passengerId;
    await widget.inboxCubit.loadNotifications(sessionState.passengerId);
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (!_isForeground) return;
    final passengerId = _activePassengerId;
    if (passengerId == null || event is! ChatMessageCreatedEvent) return;
    if (event.envelope.scope.passengerId != passengerId) return;
    final senderId = SafeParse.toStringValue(
      event.envelope.payload['sender_id'],
    );
    if (senderId.isEmpty || senderId == passengerId) return;
    final message = SafeParse.toStringValue(
      event.envelope.payload['text'],
      'You have a new message from your driver.',
    );
    final roomId = event.envelope.scope.roomId?.trim() ?? '';
    if (roomId.isEmpty) return;
    final receivedAt = event.envelope.occurredAt.toLocal();
    widget.inboxCubit.addLocalNotification(
      InboxNotification(
        id: event.envelope.id,
        title: 'New Message From Your Driver',
        message: message,
        timestamp: receivedAt,
        type: 'chat',
        isRead: false,
        roomId: roomId,
        userId: passengerId,
        peerId: senderId,
        peerName: 'Driver',
        expiresAt: receivedAt.add(const Duration(hours: 24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.navigationCoordinator.selectedIndex;
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
            _activePassengerId = null;
            unawaited(widget.realtimeClient.stop());
            if (!widget.inboxCubit.isClosed) {
              widget.inboxCubit.clearSessionData();
            }
          case SessionLoading():
            break;
        }
      },
      child: PopScope(
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
                padding: EdgeInsets.only(bottom: bottomPadding + 10),
                child: FractionallySizedBox(
                  widthFactor: 0.94,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: PassengerFloatingTabBar(
                      selectedIndex: sel,
                      onDestinationSelected: _onItemTapped,
                      inboxCubit: widget.inboxCubit,
                      pagePosition: widget.navigationCoordinator.pagePosition,
                    ),
                  ),
                ),
              );
            },
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

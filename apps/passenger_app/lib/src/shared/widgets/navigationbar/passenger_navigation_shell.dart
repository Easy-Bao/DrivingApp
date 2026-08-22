import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/guest_action_bar_widget.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_floating_tab_bar.dart';
import 'package:shared_core/shared_core.dart';

class PassengerTabNavigationCoordinator extends ChangeNotifier {
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

class PassengerTabBranchContainer extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final ValueChanged<int> onNavigationSettled;

  const PassengerTabBranchContainer({
    super.key,
    required this.navigationShell,
    required this.children,
    required this.onNavigationSettled,
  });

  @override
  State<PassengerTabBranchContainer> createState() =>
      _PassengerTabBranchContainerState();
}

class _PassengerTabBranchContainerState
    extends State<PassengerTabBranchContainer> {
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
  void didUpdateWidget(covariant PassengerTabBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = widget.navigationShell.currentIndex;
    if (_isUserDragging || targetIndex == _activeIndex) return;

    _activeIndex = targetIndex;
    _settleExternalNavigation(targetIndex);
    _animateToPage(targetIndex);
  }

  void _settleExternalNavigation(int targetIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.navigationShell.currentIndex != targetIndex) {
        return;
      }
      widget.onNavigationSettled(targetIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surface,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: PageView(
          key: const ValueKey<String>('passenger-tab-page-view'),
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

    final direction = movement > 0 ? 1 : -1;
    final adjacentIndex = startIndex + direction;
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
    final currentPage = _pageController.page?.round();
    if (currentPage == index) return;
    unawaited(
      _pageController.animateToPage(
        index,
        duration: _pageAnimationDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class PassengerShellLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final InboxCubit inboxCubit;
  final RealtimeWebSocketClient realtimeClient;
  final PassengerTabNavigationCoordinator navigationCoordinator;

  const PassengerShellLayout({
    super.key,
    required this.navigationShell,
    required this.inboxCubit,
    required this.realtimeClient,
    required this.navigationCoordinator,
  });

  @override
  State<PassengerShellLayout> createState() => _PassengerShellLayoutState();
}

class _PassengerShellLayoutState extends State<PassengerShellLayout> {
  String? _loadedInboxPassengerId;
  String? _activePassengerId;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
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
    unawaited(_realtimeSubscription?.cancel());
    super.dispose();
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
    unawaited(widget.realtimeClient.start());
    if (sessionState.passengerId == _loadedInboxPassengerId) return;
    _loadedInboxPassengerId = sessionState.passengerId;
    await widget.inboxCubit.loadNotifications(sessionState.passengerId);
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
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

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger/src/app/navigation/floating_tab_bar.dart';
import 'package:passenger/src/app/navigation/navigation_shell.dart';
import 'package:passenger/src/features/auth/domain/entities/session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/inbox_routes.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/profile/profile_routes.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';

void main() {
  testWidgets('realtime follows the passenger app lifecycle', (tester) async {
    final sessionBloc = SessionBloc(sessionRepository: _SessionRepositoryStub())
      ..add(const SessionAuthenticatedRequested(passengerId: 'passenger-1'));
    final inboxCubit = InboxCubit(inboxRepository: _InboxRepositoryStub());
    final connector = _TrackingRealtimeSocketConnector();
    final realtimeClient = RealtimeWebSocketClient(
      uri: Uri.parse('ws://localhost/realtime'),
      tokenProvider: () async => 'test-token',
      connector: connector,
      reconnectDelay: (_) => const Duration(minutes: 1),
    );
    final navigationCoordinator = TabNavigationCoordinator();
    final lifecycleCoordinator = AppLifecycleCoordinator();
    final router = _createRouter(
      inboxCubit,
      realtimeClient,
      navigationCoordinator,
      lifecycleCoordinator,
    );
    addTearDown(() async {
      router.dispose();
      await sessionBloc.close();
      await inboxCubit.close();
      await realtimeClient.dispose();
      navigationCoordinator.dispose();
      await lifecycleCoordinator.dispose();
    });

    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: sessionBloc,
        child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(connector.connectionCount, 1);
    expect(realtimeClient.isConnected, isTrue);

    lifecycleCoordinator.update(isForeground: false);
    await tester.pumpAndSettle();

    expect(realtimeClient.isConnected, isFalse);
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(connector.closeCount, 1);

    lifecycleCoordinator.update(isForeground: true);
    await tester.pumpAndSettle();

    expect(connector.connectionCount, 2);
    expect(realtimeClient.isConnected, isTrue);
  });

  testWidgets('tab changes, named navigation, and swipes stay synchronized', (
    tester,
  ) async {
    final sessionBloc = SessionBloc(sessionRepository: _SessionRepositoryStub())
      ..add(const SessionAuthenticatedRequested(passengerId: 'passenger-1'));
    final inboxCubit = InboxCubit(inboxRepository: _InboxRepositoryStub());
    final realtimeClient = RealtimeWebSocketClient(
      uri: Uri.parse('ws://localhost/realtime'),
      tokenProvider: () async => 'test-token',
      connector: _RealtimeSocketConnectorStub(),
    );
    final navigationCoordinator = TabNavigationCoordinator();
    final lifecycleCoordinator = AppLifecycleCoordinator();
    final router = _createRouter(
      inboxCubit,
      realtimeClient,
      navigationCoordinator,
      lifecycleCoordinator,
    );
    addTearDown(() async {
      router.dispose();
      await sessionBloc.close();
      await inboxCubit.close();
      await realtimeClient.dispose();
      navigationCoordinator.dispose();
      await lifecycleCoordinator.dispose();
    });

    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: sessionBloc,
        child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
    final tabBar = find.byType(FloatingTabBar);
    expect(tester.getSize(tabBar).height, FloatingTabBar.height);
    expect(
      find.descendant(of: tabBar, matching: find.byType(AnimatedScale)),
      findsNothing,
    );
    void expectStaticDestination(int index, String label) {
      final item = find.byKey(
        ValueKey<String>('passenger-floating-tab-item-$index'),
      );
      final labelWidget = tester.widget<Text>(
        find.descendant(of: item, matching: find.text(label)),
      );
      final iconWidget = tester.widget<Icon>(
        find.descendant(of: item, matching: find.byType(Icon)),
      );
      final inkWell = tester.widget<InkWell>(item);
      expect(
        labelWidget.style?.fontSize,
        AppTheme.main.textTheme.labelMedium?.fontSize,
      );
      expect(labelWidget.style?.fontWeight, FontWeight.w500);
      expect(iconWidget.size, AppSize.navigationIcon);
      expect(inkWell.splashFactory, NoSplash.splashFactory);
      expect(
        inkWell.overlayColor?.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
      expect(
        inkWell.overlayColor?.resolve({WidgetState.hovered}),
        Colors.transparent,
      );
      expect(
        inkWell.overlayColor?.resolve({WidgetState.focused}),
        AppTheme.main.colorScheme.primary.withValues(alpha: 0.12),
      );
    }

    expectStaticDestination(0, 'Home');
    expectStaticDestination(1, 'Activity');
    expectStaticDestination(2, 'Inbox');
    expectStaticDestination(3, 'Profile');
    expect(tester.takeException(), isNull);
    final indicator = find.byKey(
      const ValueKey<String>('passenger-floating-tab-indicator'),
    );
    expect(indicator, findsOneWidget);
    double capsuleScale(int index) {
      final capsule = find.byKey(
        ValueKey<String>('passenger-floating-tab-indicator-$index'),
      );
      return capsule.evaluate().isEmpty
          ? 0
          : tester.widget<Transform>(capsule).transform[0];
    }

    double capsuleOpacity(int index) {
      final capsule = find.byKey(
        ValueKey<String>('passenger-floating-tab-indicator-$index'),
      );
      if (capsule.evaluate().isEmpty) return 0;
      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(of: capsule, matching: find.byType(DecoratedBox)),
      );
      return (decoratedBox.decoration as BoxDecoration).color?.a ?? 0;
    }

    final initialHomeCapsuleScale = capsuleScale(0);

    // A first-use swipe must load the adjacent branch while the page is still
    // following the finger. The active capsules should follow the same live
    // page allocation before the gesture is released.
    final firstPreviewGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<String>('home-page'))),
    );
    await firstPreviewGesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('activity-page')), findsOneWidget);
    expect(capsuleScale(0), lessThan(initialHomeCapsuleScale));
    expect(capsuleScale(1), greaterThan(0));
    expect(capsuleOpacity(0), lessThan(1));
    expect(capsuleOpacity(1), greaterThan(0));
    await firstPreviewGesture.moveBy(const Offset(100, 0));
    await firstPreviewGesture.up();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, HomeRoutes.fullHomePath);

    await tester.tap(find.text('Activity'));
    await tester.pump();
    expect(router.state.uri.path, RideHistoryRoutes.fullRideHistoryPath);
    expect(find.byType(PageView), findsOneWidget);
    final initialActivityCapsuleScale = capsuleScale(1);
    await tester.pump(const Duration(milliseconds: 160));
    final middleActivityCapsuleScale = capsuleScale(1);
    expect(
      middleActivityCapsuleScale,
      greaterThan(initialActivityCapsuleScale),
    );
    await tester.pumpAndSettle();
    final finalActivityCapsuleScale = capsuleScale(1);
    expect(finalActivityCapsuleScale, greaterThan(middleActivityCapsuleScale));
    expectStaticDestination(0, 'Home');
    expectStaticDestination(1, 'Activity');
    expect(find.byKey(const ValueKey<String>('activity-page')), findsOneWidget);

    final cancelGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<String>('activity-page'))),
    );
    await cancelGesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('activity-page')), findsOneWidget);
    await cancelGesture.up();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RideHistoryRoutes.fullRideHistoryPath);

    final commitGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<String>('activity-page'))),
    );
    await commitGesture.moveBy(const Offset(500, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
    await commitGesture.up();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, HomeRoutes.fullHomePath);
    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Activity hides navigation down, reveals up and resets across tabs',
    (tester) async {
      final sessionBloc = SessionBloc(
        sessionRepository: _SessionRepositoryStub(),
      )..add(const SessionAuthenticatedRequested(passengerId: 'passenger-1'));
      final inboxCubit = InboxCubit(inboxRepository: _InboxRepositoryStub());
      final realtimeClient = RealtimeWebSocketClient(
        uri: Uri.parse('ws://localhost/realtime'),
        tokenProvider: () async => 'test-token',
        connector: _RealtimeSocketConnectorStub(),
      );
      final navigation = TabNavigationCoordinator();
      final lifecycle = AppLifecycleCoordinator();
      final controller = ScrollController();
      final itemCount = ValueNotifier(100);
      final accessible = ValueNotifier(false);
      final router = _createRouter(
        inboxCubit,
        realtimeClient,
        navigation,
        lifecycle,
        initialLocation: RideHistoryRoutes.fullRideHistoryPath,
        homePage: ListView.builder(
          key: const ValueKey('scrolling-home'),
          itemCount: 100,
          itemBuilder: (_, index) =>
              SizedBox(height: 70, child: Text('Home $index')),
        ),
        activityPage: ValueListenableBuilder<int>(
          valueListenable: itemCount,
          builder: (_, count, _) => ListView.builder(
            key: const ValueKey('scrolling-activity'),
            controller: controller,
            itemCount: count,
            itemBuilder: (_, index) =>
                SizedBox(height: 70, child: Text('Ride $index')),
          ),
        ),
      );
      addTearDown(() async {
        router.dispose();
        controller.dispose();
        itemCount.dispose();
        accessible.dispose();
        await sessionBloc.close();
        await inboxCubit.close();
        await realtimeClient.dispose();
        navigation.dispose();
        await lifecycle.dispose();
      });
      await tester.pumpWidget(
        BlocProvider<SessionBloc>.value(
          value: sessionBloc,
          child: MaterialApp.router(
            theme: AppTheme.main,
            routerConfig: router,
            builder: (context, child) => ValueListenableBuilder<bool>(
              valueListenable: accessible,
              builder: (_, enabled, _) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  accessibleNavigation: enabled,
                  disableAnimations: enabled,
                ),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Offset offset() => tester
          .widget<AnimatedSlide>(
            find.byKey(const ValueKey('passenger-tab-bar-visibility')),
          )
          .offset;
      final list = find.byKey(const ValueKey('scrolling-activity'));
      expect(offset(), Offset.zero);
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(offset(), const Offset(0, 1));
      expect(find.text('Inbox').hitTestable(), findsNothing);
      itemCount.value = 150;
      await tester.pumpAndSettle();
      expect(
        offset(),
        const Offset(0, 1),
        reason: 'appending another page keeps the current visibility',
      );
      final gesture = await tester.startGesture(tester.getCenter(list));
      await gesture.moveBy(const Offset(0, 25));
      await gesture.moveBy(const Offset(0, 5));
      await tester.pump();
      expect(
        offset(),
        Offset.zero,
        reason: 'a small upward reversal restores navigation immediately',
      );
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(offset(), const Offset(0, 1));
      router.goNamed(HomeRoutes.home);
      await tester.pumpAndSettle();
      expect(offset(), Offset.zero);
      await tester.drag(
        find.byKey(const ValueKey('scrolling-home')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        offset(),
        Offset.zero,
        reason: 'other tabs keep navigation visible',
      );
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(offset(), Offset.zero);
      expect(
        controller.offset,
        greaterThan(0),
        reason: 'returning to Activity preserves list position',
      );
      await tester.drag(list, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(offset(), const Offset(0, 1));
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        offset(),
        Offset.zero,
        reason: 'returning to the top restores navigation',
      );
      accessible.value = true;
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(
        offset(),
        Offset.zero,
        reason: 'accessible navigation stays available',
      );
      expect(
        tester
            .widget<AnimatedSlide>(
              find.byKey(const ValueKey('passenger-tab-bar-visibility')),
            )
            .duration,
        Duration.zero,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('guest sessions stay on Home and cannot swipe to another tab', (
    tester,
  ) async {
    final sessionBloc = SessionBloc(sessionRepository: _SessionRepositoryStub())
      ..add(const SessionGuestRequested());
    final inboxCubit = InboxCubit(inboxRepository: _InboxRepositoryStub());
    final realtimeClient = RealtimeWebSocketClient(
      uri: Uri.parse('ws://localhost/realtime'),
      tokenProvider: () async => 'test-token',
      connector: _RealtimeSocketConnectorStub(),
    );
    final navigationCoordinator = TabNavigationCoordinator();
    final lifecycleCoordinator = AppLifecycleCoordinator();
    final router = _createRouter(
      inboxCubit,
      realtimeClient,
      navigationCoordinator,
      lifecycleCoordinator,
      initialLocation: RideHistoryRoutes.fullRideHistoryPath,
    );
    addTearDown(() async {
      router.dispose();
      await sessionBloc.close();
      await inboxCubit.close();
      await realtimeClient.dispose();
      navigationCoordinator.dispose();
      await lifecycleCoordinator.dispose();
    });

    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: sessionBloc,
        child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, HomeRoutes.fullHomePath);
    expect(find.byType(FloatingTabBar), findsNothing);
    expect(find.text('View all'), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<String>('home-page'))),
    );
    await gesture.moveBy(const Offset(-500, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(router.state.uri.path, HomeRoutes.fullHomePath);
    expect(navigationCoordinator.selectedIndex, 0);
    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });
}

GoRouter _createRouter(
  InboxCubit inboxCubit,
  RealtimeWebSocketClient realtimeClient,
  TabNavigationCoordinator navigationCoordinator,
  AppLifecycleCoordinator lifecycleCoordinator, {
  String initialLocation = HomeRoutes.fullHomePath,
  Widget? activityPage,
  Widget? homePage,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => ShellLayout(
          inboxCubit: inboxCubit,
          bookingStates: const Stream<BookingState>.empty(),
          realtimeClient: realtimeClient,
          lifecycleCoordinator: lifecycleCoordinator,
          navigationCoordinator: navigationCoordinator,
          navigationShell: navigationShell,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            BlocBuilder<SessionBloc, SessionState>(
              builder: (context, sessionState) => TabBranchContainer(
                navigationShell: navigationShell,
                allowUserNavigation: sessionState.isAuthenticated,
                onNavigationSettled: navigationCoordinator.commit,
                onPagePositionChanged: navigationCoordinator.updatePagePosition,
                children: children,
              ),
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: HomeRoutes.home,
                path: HomeRoutes.fullHomePath,
                builder: (_, _) =>
                    homePage ??
                    const ColoredBox(
                      key: ValueKey<String>('home-page'),
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RideHistoryRoutes.rideHistory,
                path: RideHistoryRoutes.fullRideHistoryPath,
                builder: (_, _) =>
                    activityPage ??
                    const ColoredBox(
                      key: ValueKey<String>('activity-page'),
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: InboxRoutes.inbox,
                path: InboxRoutes.fullInboxPath,
                builder: (_, _) => const ColoredBox(
                  key: ValueKey<String>('inbox-page'),
                  color: Colors.white,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: ProfileRoutes.account,
                path: ProfileRoutes.fullAccountPath,
                builder: (_, _) => const ColoredBox(
                  key: ValueKey<String>('profile-page'),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _SessionRepositoryStub implements SessionRepository {
  @override
  Future<Result<Session, Failure>> clearSession() async {
    return const Ok(Session.guest());
  }

  @override
  Future<Result<Session, Failure>> restoreSession() async {
    return const Ok(Session.authenticated(passengerId: 'passenger-1'));
  }
}

class _InboxRepositoryStub implements InboxRepository {
  @override
  Future<Result<void, Failure>> markAllPassengerNotificationsAsRead(
    String passengerId,
  ) async => const Ok(null);

  @override
  Future<Result<List<InboxNotification>, Failure>> fetchPassengerNotifications(
    String passengerId,
  ) async {
    return const Ok(<InboxNotification>[]);
  }
}

class _RealtimeSocketConnectorStub implements RealtimeSocketConnector {
  @override
  Future<RealtimeSocket> connect(
    Uri uri, {
    required Map<String, String> headers,
  }) async => _RealtimeSocketStub();
}

class _RealtimeSocketStub implements RealtimeSocket {
  final _messages = StreamController<Object?>();

  @override
  Stream<Object?> get messages => _messages.stream;

  @override
  Future<void> close() => _messages.close();
}

class _TrackingRealtimeSocketConnector implements RealtimeSocketConnector {
  int connectionCount = 0;
  int closeCount = 0;

  @override
  Future<RealtimeSocket> connect(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    connectionCount++;
    return _TrackingRealtimeSocket(() => closeCount++);
  }
}

class _TrackingRealtimeSocket(this.onClose) implements RealtimeSocket {
  final void Function() onClose;
  final _messages = StreamController<Object?>();
  bool _closed = false;

  @override
  Stream<Object?> get messages => _messages.stream;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    onClose();
    await _messages.close();
  }
}

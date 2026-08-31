import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:passenger_app/src/features/inbox/inbox_routes.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_floating_tab_bar.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_navigation_shell.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

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
    final navigationCoordinator = PassengerTabNavigationCoordinator();
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
        child: MaterialApp.router(
          theme: EasyRideTheme.light,
          routerConfig: router,
        ),
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
    final navigationCoordinator = PassengerTabNavigationCoordinator();
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
        child: MaterialApp.router(
          theme: EasyRideTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
    final tabBar = find.byType(PassengerFloatingTabBar);
    expect(tester.getSize(tabBar).height, PassengerFloatingTabBar.height);
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
      expect(labelWidget.style?.fontSize, AppDesignTokens.navigationLabelSize);
      expect(labelWidget.style?.fontWeight, FontWeight.w500);
      expect(iconWidget.size, AppDesignTokens.navigationIconSize);
      expect(inkWell.splashFactory, NoSplash.splashFactory);
      expect(
        inkWell.overlayColor?.resolve({WidgetState.pressed}),
        EasyRideTheme.light.colorScheme.surface.withValues(alpha: 0),
      );
      expect(
        inkWell.overlayColor?.resolve({WidgetState.hovered}),
        EasyRideTheme.light.colorScheme.surface.withValues(alpha: 0),
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
    expect(router.state.uri.path, ActivityRoutes.fullActivityPath);
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
    expect(router.state.uri.path, ActivityRoutes.fullActivityPath);

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

    await tester.tap(
      find.byKey(const ValueKey<String>('home-view-all-activity')),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, ActivityRoutes.fullActivityPath);
    expect(navigationCoordinator.selectedIndex, 1);
    expect(find.byKey(const ValueKey<String>('activity-page')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

GoRouter _createRouter(
  InboxCubit inboxCubit,
  RealtimeWebSocketClient realtimeClient,
  PassengerTabNavigationCoordinator navigationCoordinator,
  AppLifecycleCoordinator lifecycleCoordinator,
) {
  return GoRouter(
    initialLocation: HomeRoutes.fullHomePath,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => PassengerShellLayout(
          inboxCubit: inboxCubit,
          realtimeClient: realtimeClient,
          lifecycleCoordinator: lifecycleCoordinator,
          navigationCoordinator: navigationCoordinator,
          navigationShell: navigationShell,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            PassengerTabBranchContainer(
              navigationShell: navigationShell,
              onNavigationSettled: navigationCoordinator.commit,
              onPagePositionChanged: navigationCoordinator.updatePagePosition,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: HomeRoutes.home,
                path: HomeRoutes.fullHomePath,
                builder: (context, _) => ColoredBox(
                  key: const ValueKey<String>('home-page'),
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      key: const ValueKey<String>('home-view-all-activity'),
                      onPressed: () => context.goNamed(ActivityRoutes.activity),
                      child: const Text('View all'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: ActivityRoutes.activity,
                path: ActivityRoutes.fullActivityPath,
                builder: (_, _) => const ColoredBox(
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
  Future<Either<Failure, PassengerSession>> clearSession() async {
    return const Right(PassengerSession.guest());
  }

  @override
  Future<Either<Failure, PassengerSession>> restoreSession() async {
    return const Right(
      PassengerSession.authenticated(passengerId: 'passenger-1'),
    );
  }
}

class _InboxRepositoryStub implements IInboxRepository {
  @override
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  ) async {
    return const Right(<InboxNotification>[]);
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

class _TrackingRealtimeSocket implements RealtimeSocket {
  _TrackingRealtimeSocket(this.onClose);

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

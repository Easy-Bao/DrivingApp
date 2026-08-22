import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:passenger_app/src/features/inbox/inbox_routes.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_floating_tab_bar.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets('tab changes animate and can be swiped', (tester) async {
    final sessionBloc = SessionBloc(sessionRepository: _SessionRepositoryStub())
      ..add(const SessionAuthenticatedRequested(passengerId: 'passenger-1'));
    final inboxCubit = InboxCubit(inboxRepository: _InboxRepositoryStub());
    final realtimeClient = RealtimeWebSocketClient(
      uri: Uri.parse('ws://localhost/realtime'),
      tokenProvider: () async => 'test-token',
      connector: _RealtimeSocketConnectorStub(),
    );
    final navigationCoordinator = PassengerTabNavigationCoordinator();
    final router = _createRouter(
      inboxCubit,
      realtimeClient,
      navigationCoordinator,
    );
    addTearDown(() async {
      router.dispose();
      await sessionBloc.close();
      await inboxCubit.close();
      await realtimeClient.dispose();
      navigationCoordinator.dispose();
    });

    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: sessionBloc,
        child: MaterialApp.router(routerConfig: router),
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
      expect(labelWidget.style?.fontSize, 10);
      expect(labelWidget.style?.fontWeight, FontWeight.w500);
      expect(iconWidget.size, 18);
    }

    expectStaticDestination(0, 'Home');
    expectStaticDestination(1, 'Activity');
    expectStaticDestination(2, 'Inbox');
    expectStaticDestination(3, 'Profile');
    expect(tester.takeException(), isNull);
    final indicator = find.byKey(
      const ValueKey<String>('passenger-floating-tab-indicator'),
    );
    final initialIndicatorPosition = tester.getTopLeft(indicator).dx;

    // A first-use swipe must load the adjacent branch while the page is still
    // following the finger, then return to the origin when released early.
    final firstPreviewGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<String>('home-page'))),
    );
    await firstPreviewGesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('activity-page')), findsOneWidget);
    await firstPreviewGesture.moveBy(const Offset(100, 0));
    await firstPreviewGesture.up();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, HomeRoutes.fullHomePath);

    await tester.tap(find.text('Activity'));
    await tester.pump();
    expect(router.state.uri.path, ActivityRoutes.fullActivityPath);
    expect(find.byType(PageView), findsOneWidget);
    expect(
      tester.getTopLeft(indicator).dx,
      closeTo(initialIndicatorPosition, 0.1),
    );
    await tester.pump(const Duration(milliseconds: 160));
    final middleIndicatorPosition = tester.getTopLeft(indicator).dx;
    expect(middleIndicatorPosition, greaterThan(initialIndicatorPosition));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(indicator).dx,
      greaterThan(middleIndicatorPosition),
    );
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
  });
}

GoRouter _createRouter(
  InboxCubit inboxCubit,
  RealtimeWebSocketClient realtimeClient,
  PassengerTabNavigationCoordinator navigationCoordinator,
) {
  return GoRouter(
    initialLocation: HomeRoutes.fullHomePath,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => PassengerShellLayout(
          inboxCubit: inboxCubit,
          realtimeClient: realtimeClient,
          navigationCoordinator: navigationCoordinator,
          navigationShell: navigationShell,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            PassengerTabBranchContainer(
              navigationShell: navigationShell,
              onNavigationSettled: navigationCoordinator.commit,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: HomeRoutes.home,
                path: HomeRoutes.fullHomePath,
                builder: (_, _) => const ColoredBox(
                  key: ValueKey<String>('home-page'),
                  color: Colors.white,
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

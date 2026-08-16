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
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets('tab changes animate and can be swiped', (tester) async {
    final sessionBloc = SessionBloc(sessionRepository: _SessionRepositoryStub())
      ..add(const SessionAuthenticatedRequested(passengerId: 'passenger-1'));
    final inboxCubit = InboxCubit(inboxRepository: _InboxRepositoryStub());
    final router = _createRouter(inboxCubit);
    addTearDown(() async {
      router.dispose();
      await sessionBloc.close();
      await inboxCubit.close();
    });

    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: sessionBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pump();
    expect(router.state.uri.path, ActivityRoutes.fullActivityPath);
    final forwardTranslation = tester
        .widget<FractionalTranslation>(
          find.byKey(const ValueKey<String>('passenger-tab-transition')),
        )
        .translation
        .dx;
    expect(forwardTranslation, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('passenger-tab-transition')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('activity-page')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey<String>('activity-page')),
      const Offset(220, 0),
    );
    await tester.pump();
    final backwardTranslation = tester
        .widget<FractionalTranslation>(
          find.byKey(const ValueKey<String>('passenger-tab-transition')),
        )
        .translation
        .dx;
    expect(backwardTranslation, lessThan(0));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, HomeRoutes.fullHomePath);
    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });
}

GoRouter _createRouter(InboxCubit inboxCubit) {
  return GoRouter(
    initialLocation: HomeRoutes.fullHomePath,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            PassengerShellLayout(inboxCubit: inboxCubit, child: child),
        routes: [
          GoRoute(
            name: HomeRoutes.home,
            path: HomeRoutes.fullHomePath,
            builder: (_, _) => const ColoredBox(
              key: ValueKey<String>('home-page'),
              color: Colors.white,
            ),
          ),
          GoRoute(
            name: ActivityRoutes.activity,
            path: ActivityRoutes.fullActivityPath,
            builder: (_, _) => const ColoredBox(
              key: ValueKey<String>('activity-page'),
              color: Colors.white,
            ),
          ),
          GoRoute(
            name: InboxRoutes.inbox,
            path: InboxRoutes.fullInboxPath,
            builder: (_, _) => const ColoredBox(
              key: ValueKey<String>('inbox-page'),
              color: Colors.white,
            ),
          ),
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

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history_overview.dart';
import 'package:passenger/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/presentation/pages/ride_history_page.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

void main() {
  testWidgets(
    'shows a friendly activity fallback and refreshes automatically',
    (tester) async {
      final sessionBloc = SessionBloc(
        sessionRepository: _AuthenticatedSessionRepository(),
      );
      final repository = _RecoveringRideHistoryRepository();
      addTearDown(sessionBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: AppNetworkStatusScope(
            isUnavailable: false,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<SessionBloc>.value(value: sessionBloc),
                BlocProvider<RideHistoryBloc>(
                  create: (_) => RideHistoryBloc(repository: repository),
                ),
              ],
              child: const RideHistoryPage(),
            ),
          ),
        ),
      );

      sessionBloc.add(const SessionStarted());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your activity is temporarily unavailable. We’ll try again automatically.',
        ),
        findsOneWidget,
      );
      expect(find.text('Could not load activity'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(repository.overviewCalls, 1);

      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      expect(repository.overviewCalls, 2);
      expect(find.text('No rides yet'), findsOneWidget);
      expect(
        find.text(
          'Your activity is temporarily unavailable. We’ll try again automatically.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'suppresses page status banner when network scope is unavailable to avoid overlapping banners',
    (tester) async {
      final sessionBloc = SessionBloc(
        sessionRepository: _AuthenticatedSessionRepository(),
      );
      final repository = _RecoveringRideHistoryRepository();
      addTearDown(sessionBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: AppNetworkStatusScope(
            isUnavailable: true,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<SessionBloc>.value(value: sessionBloc),
                BlocProvider<RideHistoryBloc>(
                  create: (_) => RideHistoryBloc(repository: repository),
                ),
              ],
              child: const RideHistoryPage(),
            ),
          ),
        ),
      );

      sessionBloc.add(const SessionStarted());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Server error: Activity is unavailable. Checking again automatically.',
        ),
        findsNothing,
      );
      expect(find.text('Could not load activity'), findsOneWidget);
    },
  );

  testWidgets(
    'loads the empty state when authentication resolves after the page mounts',
    (tester) async {
      final sessionBloc = SessionBloc(
        sessionRepository: _AuthenticatedSessionRepository(),
      );
      addTearDown(sessionBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>.value(value: sessionBloc),
              BlocProvider<RideHistoryBloc>(
                create: (_) =>
                    RideHistoryBloc(repository: _EmptyRideHistoryRepository()),
              ),
            ],
            child: const RideHistoryPage(),
          ),
        ),
      );

      expect(find.text('No rides yet'), findsNothing);

      sessionBloc.add(const SessionStarted());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No rides yet'), findsOneWidget);
      expect(
        find.text('Your completed and cancelled rides will appear here.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('uses a skeleton before the first result', (tester) async {
    final sessionBloc = SessionBloc(
      sessionRepository: _AuthenticatedSessionRepository(),
    );
    final repository = _PendingRideHistoryRepository();
    addTearDown(sessionBloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: sessionBloc),
            BlocProvider<RideHistoryBloc>(
              create: (_) => RideHistoryBloc(repository: repository),
            ),
          ],
          child: const RideHistoryPage(),
        ),
      ),
    );

    sessionBloc.add(const SessionStarted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('activity-loading-skeleton')),
      findsOneWidget,
    );
    expect(find.text('Loading your activity'), findsOneWidget);

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.text('No rides yet'), findsOneWidget);
  });
}

final class _AuthenticatedSessionRepository implements SessionRepository {
  @override
  Future<Result<Session, Failure>> restoreSession() async {
    return const Ok(Session.authenticated(passengerId: 'passenger-1'));
  }

  @override
  Future<Result<Session, Failure>> clearSession() async {
    return const Ok(Session.guest());
  }
}

final class _EmptyRideHistoryRepository implements RideHistoryRepository {
  @override
  Future<Result<RideHistoryOverview, Failure>> fetchRideHistoryOverview(
    String passengerId, {
    int limit = 25,
  }) async {
    return const Ok(
      RideHistoryOverview(
        rides: OffsetPage<RideHistory>(
          items: [],
          hasMore: false,
          nextOffset: null,
        ),
        weeklyFareAmount: 0,
        weeklyRideCount: 0,
      ),
    );
  }

  @override
  Future<Result<OffsetPage<RideHistory>, Failure>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  }) async {
    return const Ok(
      OffsetPage<RideHistory>(items: [], hasMore: false, nextOffset: null),
    );
  }
}

final class _PendingRideHistoryRepository implements RideHistoryRepository {
  final completer = Completer<Result<RideHistoryOverview, Failure>>();

  void complete() {
    completer.complete(
      const Ok(
        RideHistoryOverview(
          rides: OffsetPage<RideHistory>(
            items: [],
            hasMore: false,
            nextOffset: null,
          ),
          weeklyFareAmount: 0,
          weeklyRideCount: 0,
        ),
      ),
    );
  }

  @override
  Future<Result<RideHistoryOverview, Failure>> fetchRideHistoryOverview(
    String passengerId, {
    int limit = 25,
  }) => completer.future;

  @override
  Future<Result<OffsetPage<RideHistory>, Failure>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  }) async => const Ok(
    OffsetPage<RideHistory>(items: [], hasMore: false, nextOffset: null),
  );
}

final class _RecoveringRideHistoryRepository implements RideHistoryRepository {
  int overviewCalls = 0;

  @override
  Future<Result<RideHistoryOverview, Failure>> fetchRideHistoryOverview(
    String passengerId, {
    int limit = 25,
  }) async {
    overviewCalls++;
    if (overviewCalls == 1) {
      return const Err(
        ServerFailure.withStatusCode('Activity is unavailable.', 503),
      );
    }
    return const Ok(
      RideHistoryOverview(
        rides: OffsetPage<RideHistory>(
          items: [],
          hasMore: false,
          nextOffset: null,
        ),
        weeklyFareAmount: 0,
        weeklyRideCount: 0,
      ),
    );
  }

  @override
  Future<Result<OffsetPage<RideHistory>, Failure>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  }) async => const Ok(
    OffsetPage<RideHistory>(items: [], hasMore: false, nextOffset: null),
  );
}

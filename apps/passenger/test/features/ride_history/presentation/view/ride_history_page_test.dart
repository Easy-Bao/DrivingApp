import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history_overview.dart';
import 'package:passenger/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/presentation/view/recent_activity_page.dart';
import 'package:passenger/src/features/ride_history/presentation/view/ride_history_page.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

void main() {
  testWidgets(
    'loads the empty state when authentication resolves after the page mounts',
    (tester) async {
      final sessionBloc = SessionBloc(
        sessionRepository: _AuthenticatedSessionRepository(),
      );
      final rideHistoryBloc = RideHistoryBloc(
        repository: _EmptyRideHistoryRepository(),
      );
      addTearDown(sessionBloc.close);
      addTearDown(rideHistoryBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>.value(value: sessionBloc),
              BlocProvider<RideHistoryBloc>.value(value: rideHistoryBloc),
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

  testWidgets('uses progress instead of a skeleton before the first result', (
    tester,
  ) async {
    final sessionBloc = SessionBloc(
      sessionRepository: _AuthenticatedSessionRepository(),
    );
    final repository = _PendingRideHistoryRepository();
    final rideHistoryBloc = RideHistoryBloc(repository: repository);
    addTearDown(sessionBloc.close);
    addTearDown(rideHistoryBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: sessionBloc),
            BlocProvider<RideHistoryBloc>.value(value: rideHistoryBloc),
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
      findsNothing,
    );
    expect(find.text('Loading your activity'), findsOneWidget);

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.text('No rides yet'), findsOneWidget);
  });

  testWidgets('keeps Recent Activity separate from the Activity tab', (
    tester,
  ) async {
    final sessionBloc = SessionBloc(
      sessionRepository: _AuthenticatedSessionRepository(),
    );
    final rideHistoryBloc = RideHistoryBloc(
      repository: _EmptyRideHistoryRepository(),
    );
    addTearDown(sessionBloc.close);
    addTearDown(rideHistoryBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: sessionBloc),
            BlocProvider<RideHistoryBloc>.value(value: rideHistoryBloc),
          ],
          child: const RecentActivityPage(),
        ),
      ),
    );

    final recentPage = tester.widget<RideHistoryPage>(
      find.byType(RideHistoryPage),
    );
    expect(recentPage.title, 'Recent activity');
    expect(recentPage.showBackButton, isTrue);
    expect(recentPage.showHeaderSubtitle, isFalse);
    expect(recentPage.showSummary, isFalse);
    expect(recentPage.showFilters, isFalse);
    expect(
      find.byKey(const ValueKey<String>('recent-activity-back-button')),
      findsOneWidget,
    );
    expect(find.text('Your latest rides'), findsNothing);
  });
}

final class _AuthenticatedSessionRepository implements SessionRepository {
  @override
  Future<Result<PassengerSession, Failure>> restoreSession() async {
    return const Ok(PassengerSession.authenticated(passengerId: 'passenger-1'));
  }

  @override
  Future<Result<PassengerSession, Failure>> clearSession() async {
    return const Ok(PassengerSession.guest());
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

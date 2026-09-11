import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/app/theme/app_theme.dart';
import 'package:passenger/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history_overview.dart';
import 'package:passenger/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
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
          theme: AppTheme.data,
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
}

final class _AuthenticatedSessionRepository implements SessionRepository {
  @override
  Future<Either<Failure, PassengerSession>> restoreSession() async {
    return const Right(
      PassengerSession.authenticated(passengerId: 'passenger-1'),
    );
  }

  @override
  Future<Either<Failure, PassengerSession>> clearSession() async {
    return const Right(PassengerSession.guest());
  }
}

final class _EmptyRideHistoryRepository implements RideHistoryRepository {
  @override
  Future<Either<Failure, RideHistoryOverview>> fetchRideHistoryOverview(
    String passengerId, {
    int limit = 25,
  }) async {
    return const Right(
      RideHistoryOverview(
        rides: OffsetPage<RideHistory>(
          items: [],
          hasMore: false,
          nextOffset: null,
        ),
        weeklyFareCentavos: 0,
        weeklyRideCount: 0,
      ),
    );
  }

  @override
  Future<Either<Failure, OffsetPage<RideHistory>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  }) async {
    return const Right(
      OffsetPage<RideHistory>(items: [], hasMore: false, nextOffset: null),
    );
  }
}

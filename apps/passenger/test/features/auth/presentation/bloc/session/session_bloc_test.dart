import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository sessionRepository;

  setUp(() {
    sessionRepository = MockSessionRepository();
  });

  blocTest<SessionBloc, SessionState>(
    'restores an authenticated session from encrypted storage',
    setUp: () {
      when(() => sessionRepository.restoreSession()).thenAnswer(
        (_) async => const Right<Failure, PassengerSession>(
          PassengerSession.authenticated(
            passengerId: '42',
            passengerName: 'Avery Cruz',
          ),
        ),
      );
    },
    build: () => SessionBloc(sessionRepository: sessionRepository),
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [
      const SessionLoading(),
      const AuthenticatedSession(
        passengerId: '42',
        passengerName: 'Avery Cruz',
      ),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'defaults to guest mode when no stored session exists',
    setUp: () {
      when(() => sessionRepository.restoreSession()).thenAnswer(
        (_) async =>
            const Right<Failure, PassengerSession>(PassengerSession.guest()),
      );
    },
    build: () => SessionBloc(sessionRepository: sessionRepository),
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [const SessionLoading(), const GuestSession()],
  );

  blocTest<SessionBloc, SessionState>(
    'clears the authenticated session on logout',
    setUp: () {
      when(() => sessionRepository.clearSession()).thenAnswer(
        (_) async =>
            const Right<Failure, PassengerSession>(PassengerSession.guest()),
      );
    },
    build: () => SessionBloc(sessionRepository: sessionRepository),
    seed: () => const AuthenticatedSession(passengerId: '42'),
    act: (bloc) => bloc.add(const SessionLogoutRequested()),
    expect: () => [const SessionLoading(), const GuestSession()],
    verify: (_) {
      verify(() => sessionRepository.clearSession()).called(1);
    },
  );
}

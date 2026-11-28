import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/entities/session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository sessionRepository;

  setUp(() {
    sessionRepository = MockSessionRepository();
    when(() => sessionRepository.clearSession())
        .thenAnswer((_) async => const Ok<Session, Failure>(Session.guest()));
  });

  blocTest<SessionBloc, SessionState>(
    'restores an authenticated session from encrypted storage',
    setUp: () {
      when(() => sessionRepository.restoreSession()).thenAnswer(
        (_) async => const Ok<Session, Failure>(
          Session.authenticated(passengerId: '42', passengerName: 'Avery Cruz'),
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
      when(() => sessionRepository.restoreSession())
          .thenAnswer((_) async => const Ok<Session, Failure>(Session.guest()));
    },
    build: () => SessionBloc(sessionRepository: sessionRepository),
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [const SessionLoading(), const GuestSession()],
  );

  blocTest<SessionBloc, SessionState>(
    'clears the authenticated session on logout',
    setUp: () {
      when(() => sessionRepository.clearSession())
          .thenAnswer((_) async => const Ok<Session, Failure>(Session.guest()));
    },
    build: () => SessionBloc(sessionRepository: sessionRepository),
    seed: () => const AuthenticatedSession(passengerId: '42'),
    act: (bloc) => bloc.add(const SessionLogoutRequested()),
    expect: () => [
      const SessionLoading(),
      const GuestSession(wasSignedOut: true),
    ],
    verify: (_) {
      verify(() => sessionRepository.clearSession()).called(1);
    },
  );

  blocTest<SessionBloc, SessionState>(
    'marks guest session as expired when requested by token expiry',
    build: () => SessionBloc(sessionRepository: sessionRepository),
    seed: () => const AuthenticatedSession(passengerId: '42'),
    act: (bloc) => bloc.add(const SessionGuestRequested(expired: true)),
    expect: () => [const GuestSession(wasExpired: true)],
    verify: (_) {
      verify(() => sessionRepository.clearSession()).called(1);
    },
  );

  test(
    'does not let a late restore overwrite a newer guest transition',
    () async {
      final restore = Completer<Result<Session, Failure>>();
      when(() => sessionRepository.restoreSession())
          .thenAnswer((_) => restore.future);
      final bloc = SessionBloc(sessionRepository: sessionRepository);
      final states = <SessionState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const SessionStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SessionGuestRequested());
      await Future<void>.delayed(Duration.zero);
      restore.complete(
        const Ok<Session, Failure>(
          Session.authenticated(passengerId: 'late-restore'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.last, const GuestSession());
      verify(() => sessionRepository.clearSession()).called(1);
      await subscription.cancel();
      await bloc.close();
    },
  );

  test('Session.guest reports guest mode and is not authenticated', () {
    const guest = Session.guest();
    expect(guest.mode, SessionMode.guest);
    expect(guest.passengerId, isNull);
    expect(guest.isAuthenticated, isFalse);
  });

  test(
    'does not let a slow guest clear overwrite a newer authenticated session',
    () async {
      final clearCompleter = Completer<Result<Session, Failure>>();
      when(() => sessionRepository.clearSession())
          .thenAnswer((_) => clearCompleter.future);
      final bloc = SessionBloc(sessionRepository: sessionRepository);
      final states = <SessionState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const SessionGuestRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const SessionAuthenticatedRequested(
          passengerId: '42',
          passengerName: 'Avery Cruz',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      clearCompleter.complete(const Ok<Session, Failure>(Session.guest()));
      await Future<void>.delayed(Duration.zero);

      expect(
        states.last,
        const AuthenticatedSession(
          passengerId: '42',
          passengerName: 'Avery Cruz',
        ),
      );
      await subscription.cancel();
      await bloc.close();
    },
  );
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/session_repository.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository _sessionRepository;

  SessionBloc({required SessionRepository sessionRepository})
    : _sessionRepository = sessionRepository,
      super(const SessionLoading()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionAuthenticatedRequested>(_onSessionAuthenticatedRequested);
    on<SessionGuestRequested>(_onSessionGuestRequested);
    on<SessionLogoutRequested>(_onSessionLogoutRequested);
  }

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    final result = await _sessionRepository.restoreSession();
    result.fold(
      (failure) => emit(SessionFailure(failure.message)),
      (session) => emit(_stateFor(session)),
    );
  }

  void _onSessionAuthenticatedRequested(
    SessionAuthenticatedRequested event,
    Emitter<SessionState> emit,
  ) {
    final passengerId = event.passengerId.trim();
    if (passengerId.isEmpty) {
      emit(const SessionFailure('Passenger session is unavailable.'));
      return;
    }
    emit(AuthenticatedSession(passengerId: passengerId));
  }

  void _onSessionGuestRequested(
    SessionGuestRequested event,
    Emitter<SessionState> emit,
  ) {
    emit(const GuestSession());
  }

  Future<void> _onSessionLogoutRequested(
    SessionLogoutRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    final result = await _sessionRepository.clearSession();
    result.fold(
      (failure) => emit(SessionFailure(failure.message)),
      (session) => emit(_stateFor(session)),
    );
  }

  SessionState _stateFor(PassengerSession session) {
    final passengerId = session.passengerId;
    if (session.isAuthenticated && passengerId != null) {
      return AuthenticatedSession(passengerId: passengerId);
    }
    return const GuestSession();
  }
}

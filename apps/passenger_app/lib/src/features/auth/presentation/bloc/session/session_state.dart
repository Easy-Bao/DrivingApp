part of 'session_bloc.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  bool get isAuthenticated => this is AuthenticatedSession;

  @override
  List<Object?> get props => [];
}

final class const SessionLoading() extends SessionState;

final class const GuestSession() extends SessionState;

final class const AuthenticatedSession({
  required final String passengerId,
  final String passengerName = '',
}) extends SessionState {
  @override
  List<Object?> get props => [passengerId, passengerName];
}

final class const SessionFailure(final String message) extends SessionState {
  @override
  List<Object?> get props => [message];
}

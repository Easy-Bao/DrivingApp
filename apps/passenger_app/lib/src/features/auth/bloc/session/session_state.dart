part of 'session_bloc.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  bool get isAuthenticated => this is AuthenticatedSession;

  @override
  List<Object?> get props => [];
}

final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class GuestSession extends SessionState {
  const GuestSession();
}

final class AuthenticatedSession extends SessionState {
  final String passengerId;
  final String passengerName;

  const AuthenticatedSession({
    required this.passengerId,
    this.passengerName = '',
  });

  @override
  List<Object?> get props => [passengerId, passengerName];
}

final class SessionFailure extends SessionState {
  final String message;

  const SessionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

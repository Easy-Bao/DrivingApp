part of 'session_bloc.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

final class SessionStarted extends SessionEvent {
  const SessionStarted();
}

final class SessionAuthenticatedRequested extends SessionEvent {
  final String passengerId;

  const SessionAuthenticatedRequested({required this.passengerId});

  @override
  List<Object?> get props => [passengerId];
}

final class SessionGuestRequested extends SessionEvent {
  const SessionGuestRequested();
}

final class SessionLogoutRequested extends SessionEvent {
  const SessionLogoutRequested();
}

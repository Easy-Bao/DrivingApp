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
  final String passengerName;

  const SessionAuthenticatedRequested({
    required this.passengerId,
    this.passengerName = '',
  });

  @override
  List<Object?> get props => [passengerId, passengerName];
}

final class SessionGuestRequested extends SessionEvent {
  const SessionGuestRequested();
}

final class SessionLogoutRequested extends SessionEvent {
  const SessionLogoutRequested();
}

part of 'session_bloc.dart';

sealed class const SessionEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const SessionStarted() extends SessionEvent {}

final class const SessionAuthenticatedRequested({
  required this.passengerId,
  this.passengerName = '',
}) extends SessionEvent {
  final String passengerId;
  final String passengerName;

  @override
  List<Object?> get props => [passengerId, passengerName];
}

final class const SessionGuestRequested({this.expired = false})
    extends SessionEvent {
  final bool expired;

  @override
  List<Object?> get props => [expired];
}

final class const SessionLogoutRequested() extends SessionEvent {}

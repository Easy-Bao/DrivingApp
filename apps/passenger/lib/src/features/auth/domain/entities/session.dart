import 'package:equatable/equatable.dart';

enum SessionMode { guest, authenticated }

final class Session extends Equatable {
  const Session.authenticated({
    required this.passengerId,
    this.passengerName = '',
  }) : mode = SessionMode.authenticated;

  const Session.guest()
    : mode = SessionMode.guest,
      passengerId = null,
      passengerName = '';

  final SessionMode mode;
  final String? passengerId;
  final String passengerName;

  bool get isAuthenticated =>
      mode == SessionMode.authenticated &&
      (passengerId?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [mode, passengerId, passengerName];
}

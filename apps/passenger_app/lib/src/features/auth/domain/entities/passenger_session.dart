import 'package:equatable/equatable.dart';

enum SessionMode { guest, authenticated }

class PassengerSession extends Equatable {
  final SessionMode mode;
  final String? passengerId;
  final String passengerName;

  const PassengerSession.guest()
    : mode = SessionMode.guest,
      passengerId = null,
      passengerName = '';

  const PassengerSession.authenticated({
    required this.passengerId,
    this.passengerName = '',
  }) : mode = SessionMode.authenticated;

  bool get isAuthenticated => mode == SessionMode.authenticated;

  @override
  List<Object?> get props => [mode, passengerId, passengerName];
}

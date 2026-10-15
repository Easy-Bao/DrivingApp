import 'package:equatable/equatable.dart';

enum SessionMode { guest, authenticated }

class const PassengerSession.authenticated({
  required this.passengerId,
  this.passengerName = '',
}) extends Equatable {
  this : mode = SessionMode.authenticated;

  final SessionMode mode;
  final String? passengerId;
  final String passengerName;

  const new guest() : this.authenticated(passengerId: null);

  bool get isAuthenticated => mode == SessionMode.authenticated;

  @override
  List<Object?> get props => [mode, passengerId, passengerName];
}

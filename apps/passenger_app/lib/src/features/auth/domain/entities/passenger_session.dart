import 'package:equatable/equatable.dart';

enum SessionMode { guest, authenticated }

class PassengerSession extends Equatable {
  final SessionMode mode;
  final String? passengerId;

  const PassengerSession.guest() : mode = SessionMode.guest, passengerId = null;

  const PassengerSession.authenticated({required this.passengerId})
    : mode = SessionMode.authenticated;

  bool get isAuthenticated => mode == SessionMode.authenticated;

  @override
  List<Object?> get props => [mode, passengerId];
}

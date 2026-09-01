import 'package:equatable/equatable.dart';

sealed class const ForgotPasswordEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

class const ForgotPasswordSubmitted({required this.email})
    extends ForgotPasswordEvent {
  final String email;

  @override
  List<Object?> get props => [email];
}

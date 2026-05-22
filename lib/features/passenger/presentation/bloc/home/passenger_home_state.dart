import 'package:equatable/equatable.dart';

abstract class PassengerHomeState extends Equatable {
  const PassengerHomeState();

  @override
  List<Object?> get props => [];
}

class PassengerHomeInitial extends PassengerHomeState {
  final String address;

  const PassengerHomeInitial({required this.address});

  @override
  List<Object?> get props => [address];
}

class PassengerHomeLoading extends PassengerHomeState {}

class PassengerHomeLoaded extends PassengerHomeState {
  final String address;

  const PassengerHomeLoaded({required this.address});

  @override
  List<Object?> get props => [address];
}

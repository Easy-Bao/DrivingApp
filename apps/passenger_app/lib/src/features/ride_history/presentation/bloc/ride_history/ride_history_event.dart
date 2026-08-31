part of 'ride_history_bloc.dart';

sealed class RideHistoryEvent extends Equatable {
  const RideHistoryEvent();

  @override
  List<Object?> get props => [];
}

final class LoadRideHistoryEvent extends RideHistoryEvent {
  final String passengerId;

  const LoadRideHistoryEvent({required this.passengerId});

  @override
  List<Object?> get props => [passengerId];
}

final class RefreshRideHistoryEvent extends RideHistoryEvent {
  final String passengerId;

  const RefreshRideHistoryEvent({required this.passengerId});

  @override
  List<Object?> get props => [passengerId];
}

final class LoadMoreRideHistoryEvent extends RideHistoryEvent {
  final String passengerId;

  const LoadMoreRideHistoryEvent({required this.passengerId});

  @override
  List<Object?> get props => [passengerId];
}

part of 'ride_history_bloc.dart';

sealed class const RideHistoryEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const LoadRideHistoryEvent({required this.passengerId})
    extends RideHistoryEvent {
  final String passengerId;

  @override
  List<Object?> get props => [passengerId];
}

final class const RefreshRideHistoryEvent({required this.passengerId})
    extends RideHistoryEvent {
  final String passengerId;

  @override
  List<Object?> get props => [passengerId];
}

final class const LoadMoreRideHistoryEvent({required this.passengerId})
    extends RideHistoryEvent {
  final String passengerId;

  @override
  List<Object?> get props => [passengerId];
}

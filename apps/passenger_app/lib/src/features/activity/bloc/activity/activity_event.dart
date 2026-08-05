part of 'activity_bloc.dart';

sealed class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

final class LoadActivityEvent extends ActivityEvent {
  final String passengerId;

  const LoadActivityEvent({required this.passengerId});

  @override
  List<Object?> get props => [passengerId];
}

final class RefreshActivityEvent extends ActivityEvent {
  final String passengerId;

  const RefreshActivityEvent({required this.passengerId});

  @override
  List<Object?> get props => [passengerId];
}

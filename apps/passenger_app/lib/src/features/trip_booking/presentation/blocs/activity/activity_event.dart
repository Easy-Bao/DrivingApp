part of 'activity_bloc.dart';

/// Events driving the [ActivityBloc] state machine.
abstract class ActivityEvent {}

class LoadActivityEvent extends ActivityEvent {
  final String passengerId;
  LoadActivityEvent({required this.passengerId});
}

class RefreshActivityEvent extends ActivityEvent {
  final String passengerId;
  RefreshActivityEvent({required this.passengerId});
}

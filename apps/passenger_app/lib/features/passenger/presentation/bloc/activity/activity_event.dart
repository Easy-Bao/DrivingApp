part of 'activity_bloc.dart';

/**
 * Events driving the [ActivityBloc] state machine.
 */
abstract class ActivityEvent {}

/**
 * Dispatched on screen mount to load the passenger's ride history.
 * [passengerId] is read from SharedPreferences after successful login.
 */
class LoadActivityEvent extends ActivityEvent {
  final String passengerId;
  LoadActivityEvent({required this.passengerId});
}

/**
 * Dispatched when the user pulls-to-refresh to force a reload.
 */
class RefreshActivityEvent extends ActivityEvent {
  final String passengerId;
  RefreshActivityEvent({required this.passengerId});
}

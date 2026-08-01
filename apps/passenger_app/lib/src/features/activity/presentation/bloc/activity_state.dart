part of 'activity_bloc.dart';

abstract class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<RideHistoryModel> past;
  final List<RideHistoryModel> upcoming;

  ActivityLoaded({required this.past, required this.upcoming});
}

class ActivityError extends ActivityState {
  final String message;
  ActivityError({required this.message});
}

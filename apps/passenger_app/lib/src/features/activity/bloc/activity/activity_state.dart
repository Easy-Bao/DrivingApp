part of 'activity_bloc.dart';

sealed class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object?> get props => [];
}

final class ActivityInitial extends ActivityState {
  const ActivityInitial();
}

final class ActivityLoading extends ActivityState {
  const ActivityLoading();
}

final class ActivityLoaded extends ActivityState {
  final List<RideHistoryModel> past;
  final List<RideHistoryModel> upcoming;

  const ActivityLoaded({required this.past, required this.upcoming});

  @override
  List<Object?> get props => [past, upcoming];
}

final class ActivityError extends ActivityState {
  final String message;

  const ActivityError({required this.message});

  @override
  List<Object?> get props => [message];
}

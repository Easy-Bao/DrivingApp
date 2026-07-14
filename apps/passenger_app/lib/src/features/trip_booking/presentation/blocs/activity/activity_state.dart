part of 'activity_bloc.dart';

/// Immutable state tree for [ActivityBloc].
///
/// Separates rides into [past] (completed or canceled) and [upcoming]
/// (in_progress, requested, accepted) so the two Activity tabs can
/// independently render without filtering in the UI layer.
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

part of 'activity_bloc.dart';

/**
 * Immutable state tree for [ActivityBloc].
 *
 * Separates rides into [past] (completed or canceled) and [upcoming]
 * (in_progress, requested, accepted) so the two Activity tabs can
 * independently render without filtering in the UI layer.
 */
abstract class ActivityState {}

/// Initial state before any event is dispatched.
class ActivityInitial extends ActivityState {}

/// Emitted while the server request is in flight.
class ActivityLoading extends ActivityState {}

/**
 * Emitted after a successful load.
 *
 * [past] holds completed and canceled rides (newest-first).
 * [upcoming] holds in_progress, requested, and accepted rides.
 */
class ActivityLoaded extends ActivityState {
  final List<RideHistoryModel> past;
  final List<RideHistoryModel> upcoming;

  ActivityLoaded({required this.past, required this.upcoming});
}

/// Emitted when the network call or mapping fails.
class ActivityError extends ActivityState {
  final String message;
  ActivityError({required this.message});
}

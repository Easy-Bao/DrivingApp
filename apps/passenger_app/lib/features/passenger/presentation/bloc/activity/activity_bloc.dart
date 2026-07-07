import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/features/passenger/data/repositories/activity_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

/**
 * BLoC managing the passenger Activity screen lifecycle.
 *
 * Handles two events:
 * - [LoadActivityEvent]: emits [ActivityLoading] → [ActivityLoaded] or [ActivityError].
 * - [RefreshActivityEvent]: same pipeline but used after a pull-to-refresh gesture.
 *
 * Rides returned by the repository are split into [past] (completed, canceled)
 * and [upcoming] (in_progress, requested, accepted) so both tab views can
 * display without redundant filtering.
 */
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _repository;

  /// Status values that belong to the "Past" tab.
  static const _pastStatuses = {'completed', 'canceled', 'cancelled'};

  /// Status values that belong to the "Upcoming" tab.
  static const _upcomingStatuses = {'in_progress', 'requested', 'accepted'};

  ActivityBloc({required ActivityRepository repository})
    : _repository = repository,
      super(ActivityInitial()) {
    on<LoadActivityEvent>(_onLoad);
    on<RefreshActivityEvent>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    await _fetchAndEmit(event.passengerId, emit);
  }

  Future<void> _onRefresh(
    RefreshActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    // Keep current data visible during refresh; no loading spinner on pull.
    await _fetchAndEmit(event.passengerId, emit);
  }

  Future<void> _fetchAndEmit(
    String passengerId,
    Emitter<ActivityState> emit,
  ) async {
    try {
      final rides = await _repository.fetchRideHistory(passengerId);
      final past =
          rides.where((r) => _pastStatuses.contains(r.status)).toList();
      final upcoming =
          rides
              .where((r) => _upcomingStatuses.contains(r.status))
              .toList();
      emit(ActivityLoaded(past: past, upcoming: upcoming));
    } on ActivityRepositoryException catch (error) {
      emit(ActivityError(message: error.message));
    } catch (error) {
      emit(ActivityError(message: 'Unexpected error: $error'));
    }
  }
}

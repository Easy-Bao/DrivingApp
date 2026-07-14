import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/activity_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

/// State controller managing the retrieval and segregation of passenger ride logs.
///
/// Divides histories into historical records (completed or cancelled) and ongoing active
/// requests (requested, accepted, arrived, in-transit) to prevent UI-level sorting.
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _repository;

  static const _pastStatuses = {
    RideStatus.completed,
    RideStatus.cancelled,
  };

  static const _upcomingStatuses = {
    RideStatus.requested,
    RideStatus.accepted,
    RideStatus.arrived,
    RideStatus.inTransit,
  };

  /// Initializes the state controller with required data repository dependencies.
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
    await _fetchAndEmit(event.passengerId, emit);
  }

  Future<void> _fetchAndEmit(
    String passengerId,
    Emitter<ActivityState> emit,
  ) async {
    final result = await _repository.fetchRideHistory(passengerId);
    result.fold(
      (failure) => emit(ActivityError(message: failure.message)),
      (rides) {
        final past = rides
            .where((r) => _pastStatuses.contains(RideStatus.fromString(r.status)))
            .toList();
        final upcoming = rides
            .where((r) => _upcomingStatuses.contains(RideStatus.fromString(r.status)))
            .toList();
        emit(ActivityLoaded(past: past, upcoming: upcoming));
      },
    );
  }
}


import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/i_activity_repository.dart';
import 'package:shared_core/shared_core.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final IActivityRepository _repository;

  static const _pastStatuses = {RideStatus.completed, RideStatus.cancelled};

  static const _upcomingStatuses = {
    RideStatus.requested,
    RideStatus.accepted,
    RideStatus.arrived,
    RideStatus.inTransit,
  };

  ActivityBloc({required IActivityRepository repository})
    : _repository = repository,
      super(const ActivityInitial()) {
    on<LoadActivityEvent>(_onLoad);
    on<RefreshActivityEvent>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    if (state is! ActivityLoaded) {
      emit(const ActivityLoading());
    }
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
    result.fold((failure) => emit(ActivityError(message: failure.message)), (
      rides,
    ) {
      final past = rides
          .where((r) => _pastStatuses.contains(RideStatus.fromString(r.status)))
          .toList();
      final upcoming = rides
          .where(
            (r) => _upcomingStatuses.contains(RideStatus.fromString(r.status)),
          )
          .toList();
      emit(ActivityLoaded(past: past, upcoming: upcoming));
    });
  }
}

import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/activity_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _repository;

  static const _pastStatuses = {'completed', 'cancelled', 'canceled'};
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
    await _fetchAndEmit(event.passengerId, emit);
  }

  Future<void> _fetchAndEmit(
    String passengerId,
    Emitter<ActivityState> emit,
  ) async {
    try {
      final rides = await _repository.fetchRideHistory(passengerId);
      final past = rides
          .where((r) => _pastStatuses.contains(r.status))
          .toList();
      final upcoming = rides
          .where((r) => _upcomingStatuses.contains(r.status))
          .toList();
      emit(ActivityLoaded(past: past, upcoming: upcoming));
    } catch (error) {
      emit(ActivityError(message: ErrorHandler.getErrorMessage(error)));
    }
  }
}

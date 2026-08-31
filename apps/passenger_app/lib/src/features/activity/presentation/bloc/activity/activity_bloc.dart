import 'package:ride/ride.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/i_activity_repository.dart';
import 'package:shared_core/shared_core.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final IActivityRepository _repository;

  static const _pageSize = 25;

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
    on<LoadMoreActivityEvent>(_onLoadMore);
  }

  Future<void> _onLoad(
    LoadActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    var existingRideCount = 0;
    final currentState = state;
    if (currentState is ActivityLoaded) {
      existingRideCount =
          currentState.past.length + currentState.upcoming.length;
    }
    emit(ActivityLoading(existingRideCount: existingRideCount));
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
    final result = await _repository.fetchActivityOverview(
      passengerId,
      limit: _pageSize,
    );
    result.fold(
      (failure) =>
          emit(ActivityError(message: ErrorHandler.getErrorMessage(failure))),
      (overview) {
        emit(
          _loadedState(
            overview.rides,
            weeklyFareCentavos: overview.weeklyFareCentavos,
            weeklyRideCount: overview.weeklyRideCount,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    final current = state;
    if (current is! ActivityLoaded ||
        !current.hasMore ||
        current.nextOffset == null ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));
    final result = await _repository.fetchRideHistory(
      event.passengerId,
      limit: _pageSize,
      offset: current.nextOffset!,
    );
    result.fold(
      (failure) => emit(
        current.copyWith(
          loadMoreError: ErrorHandler.getErrorMessage(failure),
          isLoadingMore: false,
        ),
      ),
      (page) {
        final ridesById = <String, RideHistory>{
          for (final ride in current.rides) ride.id: ride,
          for (final ride in page.items) ride.id: ride,
        };
        emit(
          _loadedState(
            page,
            rides: ridesById.values.toList(),
            weeklyFareCentavos: current.weeklyFareCentavos,
            weeklyRideCount: current.weeklyRideCount,
          ),
        );
      },
    );
  }

  ActivityLoaded _loadedState(
    OffsetPage<RideHistory> page, {
    List<RideHistory>? rides,
    required int weeklyFareCentavos,
    required int weeklyRideCount,
  }) {
    final allRides = rides ?? page.items;
    final past = allRides
        .where((r) => _pastStatuses.contains(RideStatus.fromString(r.status)))
        .toList();
    final upcoming = allRides
        .where(
          (r) => _upcomingStatuses.contains(RideStatus.fromString(r.status)),
        )
        .toList();
    return ActivityLoaded(
      past: past,
      upcoming: upcoming,
      hasMore: page.hasMore,
      nextOffset: page.nextOffset,
      weeklyFareCentavos: weeklyFareCentavos,
      weeklyRideCount: weeklyRideCount,
    );
  }
}

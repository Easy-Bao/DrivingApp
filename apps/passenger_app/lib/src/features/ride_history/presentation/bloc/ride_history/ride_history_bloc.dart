import 'package:passenger_app/src/features/active_ride/active_ride.dart';
import 'package:passenger_app/src/features/ride_history/ride_history.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:foundation/foundation.dart';

part 'ride_history_event.dart';
part 'ride_history_state.dart';

class RideHistoryBloc extends Bloc<RideHistoryEvent, RideHistoryState> {
  final RideHistoryRepository _repository;

  static const _pageSize = 25;

  static const _pastStatuses = {RideStatus.completed, RideStatus.cancelled};

  static const _upcomingStatuses = {
    RideStatus.requested,
    RideStatus.accepted,
    RideStatus.arrived,
    RideStatus.inTransit,
  };

  RideHistoryBloc({required RideHistoryRepository repository})
    : _repository = repository,
      super(const RideHistoryInitial()) {
    on<LoadRideHistoryEvent>(_onLoad);
    on<RefreshRideHistoryEvent>(_onRefresh);
    on<LoadMoreRideHistoryEvent>(_onLoadMore);
  }

  Future<void> _onLoad(
    LoadRideHistoryEvent event,
    Emitter<RideHistoryState> emit,
  ) async {
    var existingRideCount = 0;
    final currentState = state;
    if (currentState is RideHistoryLoaded) {
      existingRideCount =
          currentState.past.length + currentState.upcoming.length;
    }
    emit(RideHistoryLoading(existingRideCount: existingRideCount));
    await _fetchAndEmit(event.passengerId, emit);
  }

  Future<void> _onRefresh(
    RefreshRideHistoryEvent event,
    Emitter<RideHistoryState> emit,
  ) async {
    await _fetchAndEmit(event.passengerId, emit);
  }

  Future<void> _fetchAndEmit(
    String passengerId,
    Emitter<RideHistoryState> emit,
  ) async {
    final result = await _repository.fetchRideHistoryOverview(
      passengerId,
      limit: _pageSize,
    );
    result.fold(
      (failure) => emit(
        RideHistoryError(message: ErrorHandler.getErrorMessage(failure)),
      ),
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
    LoadMoreRideHistoryEvent event,
    Emitter<RideHistoryState> emit,
  ) async {
    final current = state;
    if (current is! RideHistoryLoaded ||
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

  RideHistoryLoaded _loadedState(
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
    return RideHistoryLoaded(
      past: past,
      upcoming: upcoming,
      hasMore: page.hasMore,
      nextOffset: page.nextOffset,
      weeklyFareCentavos: weeklyFareCentavos,
      weeklyRideCount: weeklyRideCount,
    );
  }
}

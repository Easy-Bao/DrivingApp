import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

part 'ride_history_event.dart';
part 'ride_history_state.dart';

class RideHistoryBloc({required this._repository, SessionBloc? sessionBloc})
    extends Bloc<RideHistoryEvent, RideHistoryState> {
  final RideHistoryRepository _repository;

  final SessionBloc? _sessionBloc = sessionBloc;
  StreamSubscription<String?>? _sessionSubscription;
  int _generation = 0;

  static String? _sessionOwner(SessionState state) => switch (state) {
    AuthenticatedSession(:final passengerId) => passengerId,
    _ => null,
  };

  bool _canLoad(String passengerId) =>
      _sessionBloc == null || _sessionOwner(_sessionBloc.state) == passengerId;

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    await super.close();
  }

  static const _pageSize = 25;

  static const _pastStatuses = {RideStatus.completed, RideStatus.cancelled};

  static const _upcomingStatuses = {
    RideStatus.requested,
    RideStatus.accepted,
    RideStatus.arrived,
    RideStatus.inTransit,
  };

  this : super(const RideHistoryInitial()) {
    on<_RideHistorySessionChanged>((event, emit) {
      emit(const RideHistoryInitial());
    });
    var owner = sessionBloc == null ? null : _sessionOwner(sessionBloc.state);
    _sessionSubscription = sessionBloc?.stream
        .map(_sessionOwner)
        .distinct()
        .listen((nextOwner) {
          if (nextOwner == owner) return;
          owner = nextOwner;
          _generation++;
          add(const _RideHistorySessionChanged());
        });
    on<LoadRideHistoryEvent>(_onLoad);
    on<RefreshRideHistoryEvent>(_onRefresh, transformer: restartable());
    on<LoadMoreRideHistoryEvent>(_onLoadMore, transformer: droppable());
  }

  Future<void> _onLoad(
    LoadRideHistoryEvent event,
    Emitter<RideHistoryState> emit,
  ) async {
    if (!_canLoad(event.passengerId)) return;
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
    if (!_canLoad(passengerId)) return;
    final generation = ++_generation;
    final result = await _repository.fetchRideHistoryOverview(
      passengerId,
      limit: _pageSize,
    );
    if (emit.isDone || generation != _generation || !_canLoad(passengerId)) {
      return;
    }
    result.fold(
      (failure) => emit(
        RideHistoryError(message: ErrorHandler.getErrorMessage(failure)),
      ),
      (overview) {
        emit(
          _loadedState(
            overview.rides,
            weeklyFareAmount: overview.weeklyFareAmount,
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
    if (!_canLoad(event.passengerId)) return;
    final generation = _generation;
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
    if (emit.isDone ||
        generation != _generation ||
        !_canLoad(event.passengerId)) {
      return;
    }
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
            weeklyFareAmount: current.weeklyFareAmount,
            weeklyRideCount: current.weeklyRideCount,
          ),
        );
      },
    );
  }

  RideHistoryLoaded _loadedState(
    OffsetPage<RideHistory> page, {
    List<RideHistory>? rides,
    required int weeklyFareAmount,
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
      weeklyFareAmount: weeklyFareAmount,
      weeklyRideCount: weeklyRideCount,
    );
  }
}

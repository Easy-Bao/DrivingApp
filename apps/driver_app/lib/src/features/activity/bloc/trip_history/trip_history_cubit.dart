import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/bloc/trip_history/trip_history_state.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';

class DriverTripHistoryCubit extends Cubit<DriverTripHistoryState> {
  static const int pageSize = 25;

  final IDriverActivityRepository _repository;
  final SecureSessionService _sessionService;

  DriverTripHistoryCubit({
    required IDriverActivityRepository repository,
    required SecureSessionService sessionService,
  }) : _repository = repository,
       _sessionService = sessionService,
       super(const DriverTripHistoryState());

  Future<void> load() => _loadTrips();

  Future<void> loadMore() async {
    final current = state;
    if (!current.hasMore ||
        current.nextOffset == null ||
        current.isLoadingMore ||
        current.isLoading) {
      return;
    }
    await _loadTrips(loadMore: true);
  }

  Future<void> _loadTrips({bool loadMore = false}) async {
    if (isClosed) return;

    final current = state;
    final offset = current.nextOffset;
    if (loadMore && offset == null) return;

    if (loadMore) {
      emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));
    } else {
      emit(
        current.copyWith(
          isLoading: true,
          isLoadingMore: false,
          hasMore: false,
          clearNextOffset: true,
          clearError: true,
          clearLoadMoreError: true,
        ),
      );
    }

    try {
      final driverId = await _sessionService.readDriverId() ?? '';
      if (driverId.trim().isEmpty) {
        _emitInitialFailure('Your driver session is unavailable.');
        return;
      }

      final result = await _repository.fetchTripHistory(
        driverId,
        limit: pageSize,
        offset: loadMore ? offset! : 0,
      );
      if (isClosed) return;

      result.fold(
        (failure) => _emitLoadFailure(
          ErrorHandler.getErrorMessage(failure),
          loadMore: loadMore,
        ),
        (page) {
          final trips = loadMore
              ? _mergeTrips(state.trips, page.items)
              : page.items;
          emit(
            state.copyWith(
              isLoading: false,
              isLoadingMore: false,
              hasMore: page.hasMore,
              nextOffset: page.nextOffset,
              clearNextOffset: page.nextOffset == null,
              clearError: true,
              clearLoadMoreError: true,
              trips: trips,
            ),
          );
        },
      );
    } catch (error) {
      _emitLoadFailure(ErrorHandler.getErrorMessage(error), loadMore: loadMore);
    }
  }

  List<Map<String, dynamic>> _mergeTrips(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> incoming,
  ) {
    final tripsById = <String, Map<String, dynamic>>{
      for (final trip in current) '${trip['id']}': trip,
      for (final trip in incoming) '${trip['id']}': trip,
    };
    return tripsById.values.toList();
  }

  void _emitInitialFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        clearNextOffset: true,
        clearLoadMoreError: true,
        errorMessage: message,
        trips: const [],
      ),
    );
  }

  void _emitLoadFailure(String message, {required bool loadMore}) {
    if (isClosed) return;
    if (loadMore) {
      emit(state.copyWith(isLoadingMore: false, loadMoreError: message));
      return;
    }
    _emitInitialFailure(message);
  }
}

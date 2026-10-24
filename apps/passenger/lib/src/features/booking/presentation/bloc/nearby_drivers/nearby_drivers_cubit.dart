import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/domain/repositories/driver_repository.dart';

final class const NearbyDriversState({
  this.drivers = const [],
  this.isLoading = false,
  this.hasLoaded = false,
  this.errorMessage,
}) extends Equatable {
  final List<Driver> drivers;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  @override
  List<Object?> get props => [drivers, isLoading, hasLoaded, errorMessage];
}

class NearbyDriversCubit extends Cubit<NearbyDriversState> {
  NearbyDriversCubit({
    required this._repository,
    required AppLifecycleCoordinator lifecycleCoordinator,
    required this._latitude,
    required this._longitude,
  }) : _lifecycleCoordinator = lifecycleCoordinator,
       super(const NearbyDriversState()) {
    _refreshTask = AppLifecyclePeriodicTask(
      lifecycleCoordinator: lifecycleCoordinator,
      interval: const Duration(seconds: 10),
      onTick: refresh,
      runImmediately: true,
    );
  }

  final DriverRepository _repository;
  final AppLifecycleCoordinator _lifecycleCoordinator;
  final double _latitude;
  final double _longitude;
  late final AppLifecyclePeriodicTask _refreshTask;

  void start() => _refreshTask.start();

  Future<void> refresh() async {
    if (isClosed || state.isLoading || !_lifecycleCoordinator.isForeground) {
      return;
    }
    emit(
      NearbyDriversState(
        drivers: state.drivers,
        hasLoaded: state.hasLoaded,
        isLoading: true,
      ),
    );
    final result = await _repository.getNearbyDriversResult(
      lat: _latitude,
      lng: _longitude,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        NearbyDriversState(
          drivers: state.drivers,
          hasLoaded: state.hasLoaded,
          errorMessage: ErrorHandler.getErrorMessage(failure),
        ),
      ),
      (drivers) {
        final byId = {for (final driver in drivers) driver.id: driver};
        final sorted = byId.values.toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        emit(
          NearbyDriversState(
            drivers: List.unmodifiable(sorted),
            hasLoaded: true,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _refreshTask.dispose();
    return super.close();
  }
}

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/bloc/home/home_state.dart';
import 'package:passenger_app/src/features/home/domain/entities/current_location.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_current_location_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_home_repository.dart';
import 'package:shared_core/shared_core.dart';

class HomeCubit extends Cubit<HomeState> {
  final IHomeRepository _repository;
  final ICurrentLocationRepository _currentLocationRepository;

  StreamSubscription<Either<Failure, CurrentLocation>>? _locationSubscription;
  Future<void> _trackedLocationLoad = Future<void>.value();
  double? _lastLat;
  double? _lastLng;
  int _trackingRevision = 0;
  int _dataRevision = 0;
  bool _isTrackingLocation = false;

  HomeCubit({
    required IHomeRepository repository,
    required ICurrentLocationRepository currentLocationRepository,
  }) : _repository = repository,
       _currentLocationRepository = currentLocationRepository,
       super(const HomeState());

  Future<void> loadHomeData({required double lat, required double lng}) async {
    if (_lastLat != null &&
        _lastLng != null &&
        state.currentAddress.isNotEmpty) {
      final deltaLat = (lat - _lastLat!).abs();
      final deltaLng = (lng - _lastLng!).abs();
      if (deltaLat < 0.0005 && deltaLng < 0.0005) {
        return;
      }
    }

    _lastLat = lat;
    _lastLng = lng;
    final dataRevision = ++_dataRevision;

    if (state.currentAddress.isEmpty && state.recentLocations.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }
    try {
      final result = await _repository.loadHomeData(lat: lat, lng: lng);

      if (isClosed || dataRevision != _dataRevision) return;
      result.fold(
        (failure) {
          dev.log('Error loading passenger home data: ${failure.message}');
          emit(state.copyWith(isLoading: false));
        },
        (homeData) => emit(
          state.copyWith(
            isLoading: false,
            currentAddress: homeData.currentAddress,
            recentLocations: homeData.recentLocations,
          ),
        ),
      );
    } catch (error) {
      dev.log('Error executing home data load: $error');
      if (isClosed || dataRevision != _dataRevision) return;
      emit(state.copyWith(isLoading: false));
    }
  }

  void updateAddress(String address) {
    _dataRevision++;
    emit(state.copyWith(currentAddress: address));
  }

  void clearLocation() {
    _dataRevision++;
    _lastLat = null;
    _lastLng = null;
    emit(state.copyWith(isLoading: false, currentAddress: ''));
  }

  Future<void> startLocationTracking() async {
    if (_isTrackingLocation) return;

    _isTrackingLocation = true;
    final trackingRevision = ++_trackingRevision;
    final previousSubscription = _locationSubscription;
    _locationSubscription = null;
    await previousSubscription?.cancel();
    if (!_isActiveTrackingRevision(trackingRevision)) return;

    _locationSubscription = _currentLocationRepository
        .watchCurrentLocation()
        .listen(
          (result) => result.fold(
            (failure) => dev.log(
              'Passenger location stream unavailable: ${failure.message}',
            ),
            (location) =>
                unawaited(_loadTrackedLocation(location, trackingRevision)),
          ),
        );

    await refreshCurrentLocation(trackingRevision: trackingRevision);
  }

  Future<void> refreshCurrentLocation({int? trackingRevision}) async {
    final expectedRevision = trackingRevision ?? _trackingRevision;
    if (!_isActiveTrackingRevision(expectedRevision)) return;

    final result = await _currentLocationRepository.getCurrentLocation();
    if (!_isActiveTrackingRevision(expectedRevision)) return;

    await result.fold(
      (failure) async =>
          dev.log('Passenger current location unavailable: ${failure.message}'),
      (location) => _loadTrackedLocation(location, expectedRevision),
    );
  }

  Future<void> stopLocationTracking({bool clearAddress = false}) async {
    _isTrackingLocation = false;
    _trackingRevision++;

    final subscription = _locationSubscription;
    _locationSubscription = null;
    if (clearAddress) {
      clearLocation();
    } else {
      _dataRevision++;
    }
    await subscription?.cancel();
  }

  Future<void> _loadTrackedLocation(
    CurrentLocation location,
    int trackingRevision,
  ) {
    final load = _trackedLocationLoad.then((_) async {
      if (!_isActiveTrackingRevision(trackingRevision)) return;
      await loadHomeData(lat: location.latitude, lng: location.longitude);
    });
    _trackedLocationLoad = load;
    return load;
  }

  bool _isActiveTrackingRevision(int trackingRevision) {
    return !isClosed &&
        _isTrackingLocation &&
        trackingRevision == _trackingRevision;
  }

  @override
  Future<void> close() async {
    _isTrackingLocation = false;
    _trackingRevision++;
    await _locationSubscription?.cancel();
    return super.close();
  }
}

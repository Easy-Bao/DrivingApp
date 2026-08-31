import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/home/home_state.dart';
import 'package:passenger_app/src/features/home/domain/entities/current_location.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_current_location_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_home_repository.dart';
import 'package:foundation/foundation.dart';

const _pickupLocationUnavailableMessage =
    'Unable to find your pickup location. Tap to retry.';

class HomeCubit extends Cubit<HomeState> {
  final IHomeRepository _repository;
  final ICurrentLocationRepository _currentLocationRepository;

  StreamSubscription<Either<Failure, CurrentLocation>>? _locationSubscription;
  CurrentLocation? _pendingTrackedLocation;
  int? _trackedLocationLoadRevision;
  bool _isLoadingTrackedLocation = false;
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
      emit(state.copyWith(isLoading: true, locationErrorMessage: ''));
    }
    try {
      final result = await _repository.loadHomeData(lat: lat, lng: lng);

      if (isClosed || dataRevision != _dataRevision) return;
      result.fold(
        (failure) {
          dev.log('Error loading passenger home data: ${failure.message}');
          emit(
            state.copyWith(
              isLoading: false,
              locationErrorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        },
        (homeData) {
          final address = homeData.currentAddress.trim();
          final displayedAddress = address.isNotEmpty
              ? address
              : state.currentAddress;
          emit(
            state.copyWith(
              isLoading: false,
              currentAddress: displayedAddress,
              locationErrorMessage: displayedAddress.isEmpty
                  ? _pickupLocationUnavailableMessage
                  : '',
              recentLocations: homeData.recentLocations,
            ),
          );
        },
      );
    } catch (error) {
      dev.log('Error executing home data load: $error');
      if (isClosed || dataRevision != _dataRevision) return;
      emit(
        state.copyWith(
          isLoading: false,
          locationErrorMessage: _pickupLocationUnavailableMessage,
        ),
      );
    }
  }

  void updateAddress(String address) {
    _dataRevision++;
    emit(state.copyWith(currentAddress: address, locationErrorMessage: ''));
  }

  void clearLocation() {
    _dataRevision++;
    _lastLat = null;
    _lastLng = null;
    emit(
      state.copyWith(
        isLoading: false,
        currentAddress: '',
        locationErrorMessage: '',
      ),
    );
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
            (failure) {
              dev.log(
                'Passenger location stream unavailable: ${failure.message}',
              );
              if (!isClosed && state.currentAddress.isEmpty) {
                emit(
                  state.copyWith(
                    isLoading: false,
                    locationErrorMessage: ErrorHandler.getErrorMessage(failure),
                  ),
                );
              }
            },
            (location) =>
                unawaited(_loadTrackedLocation(location, trackingRevision)),
          ),
        );

    await refreshCurrentLocation(trackingRevision: trackingRevision);
  }

  Future<void> refreshCurrentLocation({int? trackingRevision}) async {
    final expectedRevision = trackingRevision ?? _trackingRevision;
    if (!_isActiveTrackingRevision(expectedRevision)) return;

    if (state.currentAddress.isEmpty) {
      emit(state.copyWith(isLoading: true, locationErrorMessage: ''));
    }

    final result = await _currentLocationRepository.getCurrentLocation();
    if (!_isActiveTrackingRevision(expectedRevision)) return;

    await result.fold((failure) async {
      dev.log('Passenger current location unavailable: ${failure.message}');
      if (!isClosed && _locationSubscription == null) {
        emit(
          state.copyWith(
            isLoading: false,
            locationErrorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
      }
    }, (location) => _loadTrackedLocation(location, expectedRevision));
  }

  Future<void> stopLocationTracking({bool clearAddress = false}) async {
    _isTrackingLocation = false;
    _trackingRevision++;
    _pendingTrackedLocation = null;

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
  ) async {
    if (!_isActiveTrackingRevision(trackingRevision)) return;

    _pendingTrackedLocation = location;
    if (_isLoadingTrackedLocation) return;

    _isLoadingTrackedLocation = true;
    _trackedLocationLoadRevision = trackingRevision;
    try {
      while (_isActiveTrackingRevision(trackingRevision)) {
        final pendingLocation = _pendingTrackedLocation;
        if (pendingLocation == null) break;
        _pendingTrackedLocation = null;
        await loadHomeData(
          lat: pendingLocation.latitude,
          lng: pendingLocation.longitude,
        );
      }
    } finally {
      if (_trackedLocationLoadRevision == trackingRevision) {
        _trackedLocationLoadRevision = null;
        _isLoadingTrackedLocation = false;
      }

      final pendingLocation = _pendingTrackedLocation;
      final currentRevision = _trackingRevision;
      if (!_isLoadingTrackedLocation &&
          pendingLocation != null &&
          _isActiveTrackingRevision(currentRevision)) {
        unawaited(_loadTrackedLocation(pendingLocation, currentRevision));
      }
    }
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
    _pendingTrackedLocation = null;
    await _locationSubscription?.cancel();
    return super.close();
  }
}

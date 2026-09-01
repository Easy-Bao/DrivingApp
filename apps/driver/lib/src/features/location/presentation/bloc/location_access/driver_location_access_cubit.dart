import 'dart:async';

import 'package:maps/maps.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver/src/features/location/domain/repositories/driver_location_access_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriverLocationAccessCubit({
  required DriverLocationAccessRepository repository,
}) extends Cubit<DriverLocationAccessViewState> {
  this : _repository = repository, super(const DriverLocationAccessChecking());

  final DriverLocationAccessRepository _repository;

  StreamSubscription<LocationAccessState>? _accessStateSubscription;
  bool _isStarted = false;
  bool _hasRequestedPermission = false;

  Future<void> start() async {
    if (_isStarted) {
      await refresh();
      return;
    }

    _isStarted = true;
    _accessStateSubscription = _repository.accessStateChanges.listen(
      _applyAccessState,
      onError: (_, _) => _emitTemporaryFailure(),
    );

    try {
      final accessState = await _repository.startMonitoring();
      if (accessState == LocationAccessState.denied &&
          !_hasRequestedPermission) {
        _hasRequestedPermission = true;
        _applyAccessState(await _repository.requestPermission());
      } else {
        _applyAccessState(accessState);
      }
    } catch (_) {
      _emitTemporaryFailure();
    }
  }

  Future<void> refresh() async {
    try {
      _applyAccessState(await _repository.refresh());
    } catch (_) {
      _emitTemporaryFailure();
    }
  }

  Future<void> enable() async {
    final previousState = state;
    emit(const DriverLocationAccessChecking());

    try {
      final accessState = await _repository.refresh();
      final refreshedState = switch (accessState) {
        LocationAccessState.denied => await _repository.requestPermission(),
        LocationAccessState.serviceDisabled => await _openLocationSettings(),
        LocationAccessState.deniedForever => await _openAppSettings(),
        LocationAccessState.ready => accessState,
      };
      _applyAccessState(refreshedState);
    } catch (_) {
      if (previousState
          case final DriverLocationAccessUnavailable unavailable) {
        emit(
          DriverLocationAccessUnavailable(
            accessState: unavailable.accessState,
            message: 'Location is temporarily unavailable. Try again.',
          ),
        );
      } else {
        _emitTemporaryFailure();
      }
    }
  }

  Future<LocationAccessState> _openLocationSettings() async {
    await _repository.openLocationSettings();
    return LocationAccessState.serviceDisabled;
  }

  Future<LocationAccessState> _openAppSettings() async {
    await _repository.openAppSettings();
    return LocationAccessState.deniedForever;
  }

  void _applyAccessState(LocationAccessState accessState) {
    if (accessState == LocationAccessState.ready) {
      emit(const DriverLocationAccessReady());
      return;
    }

    emit(
      DriverLocationAccessUnavailable(
        accessState: accessState,
        message: _settingsMessage(accessState),
      ),
    );
  }

  String? _settingsMessage(LocationAccessState accessState) {
    return switch (accessState) {
      LocationAccessState.serviceDisabled =>
        'Turn on device location in Settings, then return to BaoRide.',
      LocationAccessState.deniedForever =>
        'Allow location in app Settings, then return to BaoRide.',
      LocationAccessState.denied || LocationAccessState.ready => null,
    };
  }

  void _emitTemporaryFailure() {
    emit(
      DriverLocationAccessUnavailable(
        accessState: LocationAccessState.serviceDisabled,
        message: 'Location is temporarily unavailable. Try again.',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _accessStateSubscription?.cancel();
    await _repository.dispose();
    return super.close();
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/src/domain/entities/location_access_state.dart';
import 'package:maps/src/domain/repositories/location_access_repository.dart';
import 'package:maps/src/presentation/location_access_state.dart';

class LocationAccessCubit extends Cubit<LocationAccessViewState> {
  LocationAccessCubit({required this._repository})
    : super(const LocationAccessChecking());

  final LocationAccessRepository _repository;

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
      if (isClosed) return;
      if (accessState == LocationAccessState.denied &&
          !_hasRequestedPermission) {
        _hasRequestedPermission = true;
        final requested = await _repository.requestPermission();
        _applyAccessState(requested);
      } else {
        _applyAccessState(accessState);
      }
    } catch (_) {
      _emitTemporaryFailure();
    }
  }

  Future<void> refresh({bool showChecking = false}) async {
    if (showChecking) {
      _emitIfOpen(const LocationAccessChecking());
    }
    try {
      _applyAccessState(await _repository.refresh());
    } catch (_) {
      _emitTemporaryFailure();
    }
  }

  Future<void> enable() async {
    final previousState = state;
    _emitIfOpen(const LocationAccessChecking());

    try {
      final accessState = await _repository.refresh();
      if (isClosed) return;
      final refreshedState = switch (accessState) {
        LocationAccessState.denied => await _repository.requestPermission(),
        LocationAccessState.serviceDisabled => await _openLocationSettings(),
        LocationAccessState.deniedForever => await _openAppSettings(),
        LocationAccessState.ready => accessState,
      };
      _applyAccessState(refreshedState);
    } catch (_) {
      if (previousState case final LocationAccessUnavailable unavailable) {
        _emitIfOpen(
          LocationAccessUnavailable(
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
      _emitIfOpen(const LocationAccessReady());
      return;
    }

    _emitIfOpen(
      LocationAccessUnavailable(
        accessState: accessState,
        message: _settingsMessage(accessState),
      ),
    );
  }

  String? _settingsMessage(LocationAccessState accessState) {
    return switch (accessState) {
      LocationAccessState.serviceDisabled =>
        'Turn on device location in Settings, then return to EasyRide.',
      LocationAccessState.deniedForever =>
        'Allow location in app Settings, then return to EasyRide.',
      LocationAccessState.denied || LocationAccessState.ready => null,
    };
  }

  void _emitTemporaryFailure() {
    _emitIfOpen(
      const LocationAccessUnavailable(
        accessState: LocationAccessState.serviceDisabled,
        message: 'Location is temporarily unavailable. Try again.',
      ),
    );
  }

  void _emitIfOpen(LocationAccessViewState nextState) {
    if (isClosed) return;
    emit(nextState);
  }

  @override
  Future<void> close() async {
    await _accessStateSubscription?.cancel();
    await _repository.dispose();
    return super.close();
  }
}

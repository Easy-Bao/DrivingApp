import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';

class LocationAccessCubit extends Cubit<LocationAccessViewState> {
  LocationAccessCubit({required ILocationAccessRepository repository})
    : _repository = repository,
      super(const LocationAccessChecking());

  final ILocationAccessRepository _repository;

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
      if (accessState == .denied && !_hasRequestedPermission) {
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
    emit(const LocationAccessChecking());

    try {
      final accessState = await _repository.refresh();
      final refreshedState = switch (accessState) {
        .denied => await _repository.requestPermission(),
        .serviceDisabled => await _openLocationSettings(),
        .deniedForever => await _openAppSettings(),
        .ready => accessState,
      };
      _applyAccessState(refreshedState);
    } catch (_) {
      if (previousState case final LocationAccessUnavailable unavailable) {
        emit(
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
    return .serviceDisabled;
  }

  Future<LocationAccessState> _openAppSettings() async {
    await _repository.openAppSettings();
    return .deniedForever;
  }

  void _applyAccessState(LocationAccessState accessState) {
    if (accessState == .ready) {
      emit(const LocationAccessReady());
      return;
    }

    emit(
      LocationAccessUnavailable(
        accessState: accessState,
        message: _settingsMessage(accessState),
      ),
    );
  }

  String? _settingsMessage(LocationAccessState accessState) {
    return switch (accessState) {
      .serviceDisabled =>
        'Turn on device location in Settings, then return to EasyRide.',
      .deniedForever =>
        'Allow location in app Settings, then return to EasyRide.',
      .denied || .ready => null,
    };
  }

  void _emitTemporaryFailure() {
    emit(
      const LocationAccessUnavailable(
        accessState: .serviceDisabled,
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

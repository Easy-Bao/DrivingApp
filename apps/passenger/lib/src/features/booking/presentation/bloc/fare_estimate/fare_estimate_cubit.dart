import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/booking/domain/entities/fare_estimate.dart';
import 'package:passenger/src/features/booking/domain/repositories/fare_repository.dart';

sealed class FareEstimateState extends Equatable {
  const FareEstimateState();

  @override
  List<Object?> get props => [];
}

final class FareEstimateInitial extends FareEstimateState {
  const FareEstimateInitial();
}

final class FareEstimateLoading extends FareEstimateState {
  const FareEstimateLoading();
}

final class FareEstimateLoaded extends FareEstimateState {
  const FareEstimateLoaded(this.value);

  final FareEstimate value;

  @override
  List<Object?> get props => [value];
}

final class FareEstimateFailure extends FareEstimateState {
  const FareEstimateFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FareEstimateCubit extends Cubit<FareEstimateState> {
  FareEstimateCubit({required this._repository})
    : super(const FareEstimateInitial());

  static const _failureMessage =
      'We couldn’t calculate a fare for this route. Please try again.';

  final FareRepository _repository;
  Future<void>? _activeRequest;
  Object? _activeRequestKey;
  int _requestRevision = 0;

  Future<void> estimate({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    final requestKey = Object.hash(
      distanceKm,
      durationMinutes,
      originLatitude,
      originLongitude,
      destinationLatitude,
      destinationLongitude,
    );
    final activeRequest = _activeRequest;
    if (activeRequest != null && _activeRequestKey == requestKey) {
      return activeRequest;
    }

    final revision = ++_requestRevision;
    final request = _runEstimate(
      revision,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
    );
    _activeRequest = request;
    _activeRequestKey = requestKey;
    unawaited(
      request.whenComplete(() {
        if (identical(_activeRequest, request)) {
          _activeRequest = null;
          _activeRequestKey = null;
        }
      }),
    );
    return request;
  }

  Future<void> _runEstimate(
    int revision, {
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (!isClosed) emit(const FareEstimateLoading());

    try {
      final result = await _repository.estimateFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
      );
      if (isClosed || revision != _requestRevision) return;
      result.fold(
        (_) => emit(const FareEstimateFailure(_failureMessage)),
        (value) => emit(FareEstimateLoaded(value)),
      );
    } catch (_) {
      if (!isClosed && revision == _requestRevision) {
        emit(const FareEstimateFailure(_failureMessage));
      }
    }
  }
}

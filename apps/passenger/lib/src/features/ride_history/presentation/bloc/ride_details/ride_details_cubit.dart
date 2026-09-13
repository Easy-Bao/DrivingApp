import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

final class const RideDetailsState({
  this.rideId = '',
  this.isLoading = false,
  this.ride,
  this.counterparty,
  this.passengerId = '',
  this.errorMessage,
}) extends Equatable {
  final String rideId;
  final bool isLoading;
  final RideSnapshot? ride;
  final RideCounterparty? counterparty;
  final String passengerId;
  final String? errorMessage;

  bool get canContactCounterparty =>
      counterparty?.contactAllowed == true &&
      counterparty?.userId.isNotEmpty == true;

  RideDetailsState copyWith({
    RideSnapshot? ride,
    RideCounterparty? counterparty,
    String? errorMessage,
  }) {
    return RideDetailsState(
      rideId: rideId,
      isLoading: isLoading,
      ride: ride ?? this.ride,
      counterparty: counterparty ?? this.counterparty,
      passengerId: passengerId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    rideId,
    isLoading,
    ride,
    counterparty,
    passengerId,
    errorMessage,
  ];
}

class RideDetailsCubit extends Cubit<RideDetailsState> {
  RideDetailsCubit({
    required TrackRepository repository,
    required PassengerSessionStore sessionService,
  }) : this._(repository, sessionService);

  RideDetailsCubit._(this._repository, this._sessionService)
    : super(const RideDetailsState());

  final TrackRepository _repository;
  final PassengerSessionStore _sessionService;
  Future<void>? _loadRequest;
  Future<RideCounterparty?>? _counterpartyRequest;

  Future<void> load(String rideId) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty || isClosed) return;
    if (state.rideId == normalizedRideId &&
        (state.isLoading || state.ride != null || state.counterparty != null)) {
      return;
    }

    final currentRequest = _loadRequest;
    if (currentRequest != null) {
      await currentRequest;
      return;
    }

    final request = _load(normalizedRideId);
    _loadRequest = request;
    try {
      await request;
    } finally {
      if (identical(_loadRequest, request)) _loadRequest = null;
    }
  }

  Future<void> _load(String rideId) async {
    emit(RideDetailsState(rideId: rideId, isLoading: true));

    try {
      final passengerIdFuture = _sessionService.readPassengerId();
      final rideFuture = _repository.fetchRideResult(rideId);
      final counterpartyFuture = _repository.fetchCounterpartyResult(rideId);

      final passengerId = await passengerIdFuture ?? '';
      RideSnapshot? ride;
      RideCounterparty? counterparty;
      (await rideFuture).fold((_) {}, (value) => ride = value);
      (await counterpartyFuture).fold((_) {}, (value) => counterparty = value);

      if (isClosed) return;
      emit(
        RideDetailsState(
          rideId: rideId,
          ride: ride,
          counterparty: counterparty,
          passengerId: passengerId,
          errorMessage: ride == null && counterparty == null
              ? 'Ride details are temporarily unavailable.'
              : null,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          RideDetailsState(
            rideId: rideId,
            errorMessage: 'Ride details are temporarily unavailable.',
          ),
        );
      }
    }
  }

  Future<RideCounterparty?> loadCounterpartyIfNeeded(String rideId) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty || isClosed) return null;

    final current = state.counterparty;
    if (current != null) return current;

    final currentRequest = _counterpartyRequest;
    if (currentRequest != null) return currentRequest;

    final request = _fetchCounterparty(normalizedRideId);
    _counterpartyRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_counterpartyRequest, request)) {
        _counterpartyRequest = null;
      }
    }
  }

  Future<RideCounterparty?> _fetchCounterparty(String rideId) async {
    try {
      RideCounterparty? counterparty;
      (await _repository.fetchCounterpartyResult(rideId))
          .fold((_) {}, (value) => counterparty = value);
      if (counterparty != null && !isClosed && state.rideId == rideId) {
        emit(state.copyWith(counterparty: counterparty));
      }
      return counterparty;
    } catch (_) {
      return null;
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

final class RideDetailsState extends Equatable {
  const RideDetailsState({
    this.rideId = '',
    this.isLoading = false,
    this.ride,
    this.counterparty,
    this.passengerId = '',
    this.errorMessage,
    this.submittedReview,
    this.isLoadingReview = false,
    this.isSubmittingReview = false,
    this.reviewErrorMessage,
    this.ratingErrorMessage,
  });
  final String rideId;
  final bool isLoading;
  final RideSnapshot? ride;
  final RideCounterparty? counterparty;
  final String passengerId;
  final String? errorMessage;
  final DriverReview? submittedReview;
  final bool isLoadingReview;
  final bool isSubmittingReview;
  final String? reviewErrorMessage;
  final String? ratingErrorMessage;

  bool get canContactCounterparty =>
      counterparty?.contactAllowed == true &&
      counterparty?.userId.isNotEmpty == true;

  RideDetailsState copyWith({
    RideSnapshot? ride,
    RideCounterparty? counterparty,
    String? errorMessage,
    DriverReview? submittedReview,
    bool? isLoadingReview,
    bool? isSubmittingReview,
    String? reviewErrorMessage,
    String? ratingErrorMessage,
    bool clearReviewErrorMessage = false,
    bool clearRatingErrorMessage = false,
  }) {
    return RideDetailsState(
      rideId: rideId,
      isLoading: isLoading,
      ride: ride ?? this.ride,
      counterparty: counterparty ?? this.counterparty,
      passengerId: passengerId,
      errorMessage: errorMessage ?? this.errorMessage,
      submittedReview: submittedReview ?? this.submittedReview,
      isLoadingReview: isLoadingReview ?? this.isLoadingReview,
      isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
      reviewErrorMessage: clearReviewErrorMessage
          ? null
          : reviewErrorMessage ?? this.reviewErrorMessage,
      ratingErrorMessage: clearRatingErrorMessage
          ? null
          : ratingErrorMessage ?? this.ratingErrorMessage,
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
    submittedReview,
    isLoadingReview,
    isSubmittingReview,
    reviewErrorMessage,
    ratingErrorMessage,
  ];
}

class RideDetailsCubit extends Cubit<RideDetailsState> {
  RideDetailsCubit({
    required TrackRepository repository,
    required SessionStore sessionService,
    required DriverProfileRepository profileRepository,
  }) : this._(repository, sessionService, profileRepository);

  RideDetailsCubit._(
    this._repository,
    this._sessionService,
    this._profileRepository,
  ) : super(const RideDetailsState());

  final TrackRepository _repository;
  final SessionStore _sessionService;
  final DriverProfileRepository _profileRepository;
  Future<void>? _loadRequest;
  Future<void>? _reviewRequest;
  String? _loadedReviewRideId;

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

  Future<void> loadMyReview(String rideId, {bool refresh = false}) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty ||
        isClosed ||
        state.rideId != normalizedRideId ||
        state.isLoadingReview ||
        state.submittedReview != null ||
        (!refresh && _loadedReviewRideId == normalizedRideId)) {
      return;
    }

    final currentRequest = _reviewRequest;
    if (currentRequest != null) {
      await currentRequest;
      return;
    }

    final request = _fetchMyReview(normalizedRideId);
    _reviewRequest = request;
    try {
      await request;
    } finally {
      if (identical(_reviewRequest, request)) _reviewRequest = null;
    }
  }

  Future<void> _fetchMyReview(String rideId) async {
    emit(
      state.copyWith(
        isLoadingReview: true,
        clearReviewErrorMessage: true,
        clearRatingErrorMessage: true,
      ),
    );

    final result = await _profileRepository.fetchMyRideReviewResult(rideId);
    if (isClosed || state.rideId != rideId) return;

    switch (result) {
      case Ok<DriverReview?, DomainFailure>(:final value):
        _loadedReviewRideId = rideId;
        emit(state.copyWith(submittedReview: value, isLoadingReview: false));
      case Err<DriverReview?, DomainFailure>(:final failure):
        emit(
          state.copyWith(
            isLoadingReview: false,
            reviewErrorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
    }
  }

  Future<void> submitRating({
    required String driverId,
    required String rideId,
    required int rating,
    required String comment,
  }) async {
    final normalizedRideId = rideId.trim();
    final normalizedDriverId = driverId.trim();
    if (normalizedRideId.isEmpty ||
        normalizedDriverId.isEmpty ||
        normalizedRideId != state.rideId ||
        rating < 1 ||
        rating > 5 ||
        isClosed ||
        state.isLoadingReview ||
        state.isSubmittingReview ||
        state.submittedReview != null ||
        _loadedReviewRideId != normalizedRideId) {
      return;
    }

    emit(
      state.copyWith(isSubmittingReview: true, clearRatingErrorMessage: true),
    );
    final trimmedComment = comment.trim();
    final result = await _profileRepository.submitReviewResult(
      driverId: normalizedDriverId,
      rideId: normalizedRideId,
      rating: rating.toDouble(),
      comment: trimmedComment,
    );
    if (isClosed || state.rideId != normalizedRideId) return;

    switch (result) {
      case Ok<void, DomainFailure>():
        _loadedReviewRideId = normalizedRideId;
        emit(
          state.copyWith(
            submittedReview: DriverReview(
              passengerName: '',
              comment: trimmedComment,
              rating: rating.toDouble(),
            ),
            isSubmittingReview: false,
          ),
        );
      case Err<void, DomainFailure>(:final failure):
        emit(
          state.copyWith(
            isSubmittingReview: false,
            ratingErrorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
    }
  }
}

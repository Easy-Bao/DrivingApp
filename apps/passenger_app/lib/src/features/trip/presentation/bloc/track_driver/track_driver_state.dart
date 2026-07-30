import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/track_driver_state.freezed.dart';

@freezed
sealed class TrackDriverState with _$TrackDriverState {
  const factory TrackDriverState.initial() = TrackDriverInitial;
  const factory TrackDriverState.inProgress({
    required double driverLat,
    required double driverLng,
    required double progress,
    required String eta,
    required String driverName,
    required String vehiclePlate,
    required String vehicleType,
    List<List<double>>? routePoints,
  }) = TrackDriverInProgress;
  const factory TrackDriverState.completed({
    required String driverId,
    required String driverName,
  }) = TrackDriverCompleted;
  const factory TrackDriverState.canceled() = TrackDriverCanceled;
}

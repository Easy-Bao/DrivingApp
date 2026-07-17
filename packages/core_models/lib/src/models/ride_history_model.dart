import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/ride_history_model.freezed.dart';
part 'generated/ride_history_model.g.dart';

/// RideHistoryModel represents a past passenger trip or driving log.
@freezed
abstract class RideHistoryModel with _$RideHistoryModel {
  //TODO: Chore should add or register DriverID, vehicleType
  const factory RideHistoryModel({
    required String id,
    required String pickup,
    required String destination,
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    required String date,
    required String price,
    required String status,
    @Default('') String driverName,
    @Default('') String vehiclePlate,
    @Default('') String vehicleType,
  }) = _RideHistoryModel;

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$RideHistoryModelFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/ride_history_model.freezed.dart';
part 'generated/ride_history_model.g.dart';

@freezed
abstract class RideHistoryModel with _$RideHistoryModel {
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
    required String driverId,
    required String driverName,
    required String vehiclePlate,
    required String vehicleType,
  }) = _RideHistoryModel;

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$RideHistoryModelFromJson(json);
}

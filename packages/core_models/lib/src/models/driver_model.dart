import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/driver_model.freezed.dart';
part 'generated/driver_model.g.dart';

@freezed
abstract class DriverModel with _$DriverModel {
  const factory DriverModel({
    required String id,
    required String name,
    required String vehicleType,
    required String plateNumber,
    required double rating,
    required double lat,
    required double lng,
    required double distanceKm,
    required double etaMinutes,
    required double score,
  }) = _DriverModel;

  factory DriverModel.fromJson(Map<String, dynamic> json) =>
      _$DriverModelFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'ride_status.dart';

part 'generated/ride_update.freezed.dart';
part 'generated/ride_update.g.dart';

/// RideUpdate represents the updated real-time status and driver info of an active ride.
@freezed
abstract class RideUpdate with _$RideUpdate {
  const factory RideUpdate({
    @JsonKey(fromJson: RideStatus.fromString) required RideStatus status,
    @JsonKey(name: 'driver_id') String? driverId,
    @JsonKey(name: 'driver_name', defaultValue: 'Driver')
    required String driverName,
    @JsonKey(name: 'plate_number', defaultValue: '—')
    required String vehiclePlate,
    @JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao')
    required String vehicleType,
  }) = _RideUpdate;

  factory RideUpdate.fromJson(Map<String, dynamic> json) =>
      _$RideUpdateFromJson(json);
}

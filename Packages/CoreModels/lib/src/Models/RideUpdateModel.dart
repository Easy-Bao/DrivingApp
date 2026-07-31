import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'RideStatusModel.dart';

part 'Generated/RideUpdateModel.g.dart';

@JsonSerializable()
class RideUpdate extends Equatable {
  @JsonKey(fromJson: RideStatus.fromString)
  final RideStatus status;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'driver_name', defaultValue: 'Driver')
  final String driverName;
  @JsonKey(name: 'plate_number', defaultValue: '—')
  final String vehiclePlate;
  @JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao')
  final String vehicleType;

  const RideUpdate({
    required this.status,
    this.driverId,
    this.driverName = 'Driver',
    this.vehiclePlate = '—',
    this.vehicleType = 'Bao Bao',
  });

  factory RideUpdate.fromJson(Map<String, dynamic> json) =>
      _$RideUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$RideUpdateToJson(this);

  @override
  List<Object?> get props => [
        status,
        driverId,
        driverName,
        vehiclePlate,
        vehicleType,
      ];
}


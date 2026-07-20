import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:passenger_services/src/features/bidding/data/models/bid_session_trip_model.dart';
import 'package:passenger_services/src/features/bidding/domain/entities/driver_match_result.dart';

part 'generated/driver_match_result_model.freezed.dart';
part 'generated/driver_match_result_model.g.dart';

@freezed
abstract class DriverMatchResultModel with _$DriverMatchResultModel {
  const factory DriverMatchResultModel({
    required BidSessionTripModel trip,
    required String driverId,
    required String driverName,
    required double fare,
    required String? driverRating,
    required String vehicleType,
    required String plateNumber,
  }) = _DriverMatchResultModel;

  factory DriverMatchResultModel.fromJson(Map<String, dynamic> json) =>
      _$DriverMatchResultModelFromJson(json);

  const DriverMatchResultModel._();

  DriverMatchResult toEntity() {
    return DriverMatchResult(
      trip: trip.toEntity(),
      driverId: driverId,
      driverName: driverName,
      fare: fare,
      driverRating: driverRating,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
    );
  }

  factory DriverMatchResultModel.fromEntity(DriverMatchResult entity) {
    return DriverMatchResultModel(
      trip: BidSessionTripModel.fromEntity(entity.trip),
      driverId: entity.driverId,
      driverName: entity.driverName,
      fare: entity.fare,
      driverRating: entity.driverRating,
      vehicleType: entity.vehicleType,
      plateNumber: entity.plateNumber,
    );
  }
}

import 'package:core_models/core_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:passenger_services/src/features/bidding/domain/entities/bid_session_trip.dart';

part 'generated/bid_session_trip_model.freezed.dart';
part 'generated/bid_session_trip_model.g.dart';

@freezed
abstract class BidSessionTripModel with _$BidSessionTripModel {
  const factory BidSessionTripModel({
    required String rideType,
    required double fare,
    required PlaceModel destination,
    required String distance,
    required String duration,
    String? pickupAddress,
  }) = _BidSessionTripModel;

  factory BidSessionTripModel.fromJson(Map<String, dynamic> json) =>
      _$BidSessionTripModelFromJson(json);

  const BidSessionTripModel._();

  BidSessionTrip toEntity() {
    return BidSessionTrip(
      rideType: rideType,
      fare: fare,
      destination: destination,
      distance: distance,
      duration: duration,
      pickupAddress: pickupAddress,
    );
  }

  factory BidSessionTripModel.fromEntity(BidSessionTrip entity) {
    return BidSessionTripModel(
      rideType: entity.rideType,
      fare: entity.fare,
      destination: entity.destination,
      distance: entity.distance,
      duration: entity.duration,
      pickupAddress: entity.pickupAddress,
    );
  }
}

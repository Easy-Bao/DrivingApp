// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../bid_session_trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BidSessionTripModel _$BidSessionTripModelFromJson(Map<String, dynamic> json) =>
    _BidSessionTripModel(
      rideType: json['rideType'] as String,
      fare: (json['fare'] as num).toDouble(),
      destination: PlaceModel.fromJson(
        json['destination'] as Map<String, dynamic>,
      ),
      distance: json['distance'] as String,
      duration: json['duration'] as String,
      pickupAddress: json['pickupAddress'] as String?,
    );

Map<String, dynamic> _$BidSessionTripModelToJson(
  _BidSessionTripModel instance,
) => <String, dynamic>{
  'rideType': instance.rideType,
  'fare': instance.fare,
  'destination': instance.destination,
  'distance': instance.distance,
  'duration': instance.duration,
  'pickupAddress': instance.pickupAddress,
};

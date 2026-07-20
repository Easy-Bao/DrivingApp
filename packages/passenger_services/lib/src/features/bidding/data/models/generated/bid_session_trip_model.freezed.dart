// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../bid_session_trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BidSessionTripModel {

 String get rideType; double get fare; PlaceModel get destination; String get distance; String get duration; String? get pickupAddress;
/// Create a copy of BidSessionTripModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BidSessionTripModelCopyWith<BidSessionTripModel> get copyWith => _$BidSessionTripModelCopyWithImpl<BidSessionTripModel>(this as BidSessionTripModel, _$identity);

  /// Serializes this BidSessionTripModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BidSessionTripModel&&(identical(other.rideType, rideType) || other.rideType == rideType)&&(identical(other.fare, fare) || other.fare == fare)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rideType,fare,destination,distance,duration,pickupAddress);

@override
String toString() {
  return 'BidSessionTripModel(rideType: $rideType, fare: $fare, destination: $destination, distance: $distance, duration: $duration, pickupAddress: $pickupAddress)';
}


}

/// @nodoc
abstract mixin class $BidSessionTripModelCopyWith<$Res>  {
  factory $BidSessionTripModelCopyWith(BidSessionTripModel value, $Res Function(BidSessionTripModel) _then) = _$BidSessionTripModelCopyWithImpl;
@useResult
$Res call({
 String rideType, double fare, PlaceModel destination, String distance, String duration, String? pickupAddress
});


$PlaceModelCopyWith<$Res> get destination;

}
/// @nodoc
class _$BidSessionTripModelCopyWithImpl<$Res>
    implements $BidSessionTripModelCopyWith<$Res> {
  _$BidSessionTripModelCopyWithImpl(this._self, this._then);

  final BidSessionTripModel _self;
  final $Res Function(BidSessionTripModel) _then;

/// Create a copy of BidSessionTripModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rideType = null,Object? fare = null,Object? destination = null,Object? distance = null,Object? duration = null,Object? pickupAddress = freezed,}) {
  return _then(_self.copyWith(
rideType: null == rideType ? _self.rideType : rideType // ignore: cast_nullable_to_non_nullable
as String,fare: null == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as double,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as PlaceModel,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,pickupAddress: freezed == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BidSessionTripModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceModelCopyWith<$Res> get destination {
  
  return $PlaceModelCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}
}


/// Adds pattern-matching-related methods to [BidSessionTripModel].
extension BidSessionTripModelPatterns on BidSessionTripModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BidSessionTripModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BidSessionTripModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BidSessionTripModel value)  $default,){
final _that = this;
switch (_that) {
case _BidSessionTripModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BidSessionTripModel value)?  $default,){
final _that = this;
switch (_that) {
case _BidSessionTripModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rideType,  double fare,  PlaceModel destination,  String distance,  String duration,  String? pickupAddress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BidSessionTripModel() when $default != null:
return $default(_that.rideType,_that.fare,_that.destination,_that.distance,_that.duration,_that.pickupAddress);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rideType,  double fare,  PlaceModel destination,  String distance,  String duration,  String? pickupAddress)  $default,) {final _that = this;
switch (_that) {
case _BidSessionTripModel():
return $default(_that.rideType,_that.fare,_that.destination,_that.distance,_that.duration,_that.pickupAddress);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rideType,  double fare,  PlaceModel destination,  String distance,  String duration,  String? pickupAddress)?  $default,) {final _that = this;
switch (_that) {
case _BidSessionTripModel() when $default != null:
return $default(_that.rideType,_that.fare,_that.destination,_that.distance,_that.duration,_that.pickupAddress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BidSessionTripModel extends BidSessionTripModel {
  const _BidSessionTripModel({required this.rideType, required this.fare, required this.destination, required this.distance, required this.duration, this.pickupAddress}): super._();
  factory _BidSessionTripModel.fromJson(Map<String, dynamic> json) => _$BidSessionTripModelFromJson(json);

@override final  String rideType;
@override final  double fare;
@override final  PlaceModel destination;
@override final  String distance;
@override final  String duration;
@override final  String? pickupAddress;

/// Create a copy of BidSessionTripModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BidSessionTripModelCopyWith<_BidSessionTripModel> get copyWith => __$BidSessionTripModelCopyWithImpl<_BidSessionTripModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BidSessionTripModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BidSessionTripModel&&(identical(other.rideType, rideType) || other.rideType == rideType)&&(identical(other.fare, fare) || other.fare == fare)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rideType,fare,destination,distance,duration,pickupAddress);

@override
String toString() {
  return 'BidSessionTripModel(rideType: $rideType, fare: $fare, destination: $destination, distance: $distance, duration: $duration, pickupAddress: $pickupAddress)';
}


}

/// @nodoc
abstract mixin class _$BidSessionTripModelCopyWith<$Res> implements $BidSessionTripModelCopyWith<$Res> {
  factory _$BidSessionTripModelCopyWith(_BidSessionTripModel value, $Res Function(_BidSessionTripModel) _then) = __$BidSessionTripModelCopyWithImpl;
@override @useResult
$Res call({
 String rideType, double fare, PlaceModel destination, String distance, String duration, String? pickupAddress
});


@override $PlaceModelCopyWith<$Res> get destination;

}
/// @nodoc
class __$BidSessionTripModelCopyWithImpl<$Res>
    implements _$BidSessionTripModelCopyWith<$Res> {
  __$BidSessionTripModelCopyWithImpl(this._self, this._then);

  final _BidSessionTripModel _self;
  final $Res Function(_BidSessionTripModel) _then;

/// Create a copy of BidSessionTripModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rideType = null,Object? fare = null,Object? destination = null,Object? distance = null,Object? duration = null,Object? pickupAddress = freezed,}) {
  return _then(_BidSessionTripModel(
rideType: null == rideType ? _self.rideType : rideType // ignore: cast_nullable_to_non_nullable
as String,fare: null == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as double,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as PlaceModel,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,pickupAddress: freezed == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BidSessionTripModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceModelCopyWith<$Res> get destination {
  
  return $PlaceModelCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}
}

// dart format on

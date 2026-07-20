// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../driver_match_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverMatchResultModel {

 BidSessionTripModel get trip; String get driverId; String get driverName; double get fare; String? get driverRating; String get vehicleType; String get plateNumber;
/// Create a copy of DriverMatchResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverMatchResultModelCopyWith<DriverMatchResultModel> get copyWith => _$DriverMatchResultModelCopyWithImpl<DriverMatchResultModel>(this as DriverMatchResultModel, _$identity);

  /// Serializes this DriverMatchResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverMatchResultModel&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.fare, fare) || other.fare == fare)&&(identical(other.driverRating, driverRating) || other.driverRating == driverRating)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trip,driverId,driverName,fare,driverRating,vehicleType,plateNumber);

@override
String toString() {
  return 'DriverMatchResultModel(trip: $trip, driverId: $driverId, driverName: $driverName, fare: $fare, driverRating: $driverRating, vehicleType: $vehicleType, plateNumber: $plateNumber)';
}


}

/// @nodoc
abstract mixin class $DriverMatchResultModelCopyWith<$Res>  {
  factory $DriverMatchResultModelCopyWith(DriverMatchResultModel value, $Res Function(DriverMatchResultModel) _then) = _$DriverMatchResultModelCopyWithImpl;
@useResult
$Res call({
 BidSessionTripModel trip, String driverId, String driverName, double fare, String? driverRating, String vehicleType, String plateNumber
});


$BidSessionTripModelCopyWith<$Res> get trip;

}
/// @nodoc
class _$DriverMatchResultModelCopyWithImpl<$Res>
    implements $DriverMatchResultModelCopyWith<$Res> {
  _$DriverMatchResultModelCopyWithImpl(this._self, this._then);

  final DriverMatchResultModel _self;
  final $Res Function(DriverMatchResultModel) _then;

/// Create a copy of DriverMatchResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trip = null,Object? driverId = null,Object? driverName = null,Object? fare = null,Object? driverRating = freezed,Object? vehicleType = null,Object? plateNumber = null,}) {
  return _then(_self.copyWith(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as BidSessionTripModel,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,fare: null == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as double,driverRating: freezed == driverRating ? _self.driverRating : driverRating // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of DriverMatchResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BidSessionTripModelCopyWith<$Res> get trip {
  
  return $BidSessionTripModelCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}


/// Adds pattern-matching-related methods to [DriverMatchResultModel].
extension DriverMatchResultModelPatterns on DriverMatchResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverMatchResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverMatchResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverMatchResultModel value)  $default,){
final _that = this;
switch (_that) {
case _DriverMatchResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverMatchResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _DriverMatchResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BidSessionTripModel trip,  String driverId,  String driverName,  double fare,  String? driverRating,  String vehicleType,  String plateNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverMatchResultModel() when $default != null:
return $default(_that.trip,_that.driverId,_that.driverName,_that.fare,_that.driverRating,_that.vehicleType,_that.plateNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BidSessionTripModel trip,  String driverId,  String driverName,  double fare,  String? driverRating,  String vehicleType,  String plateNumber)  $default,) {final _that = this;
switch (_that) {
case _DriverMatchResultModel():
return $default(_that.trip,_that.driverId,_that.driverName,_that.fare,_that.driverRating,_that.vehicleType,_that.plateNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BidSessionTripModel trip,  String driverId,  String driverName,  double fare,  String? driverRating,  String vehicleType,  String plateNumber)?  $default,) {final _that = this;
switch (_that) {
case _DriverMatchResultModel() when $default != null:
return $default(_that.trip,_that.driverId,_that.driverName,_that.fare,_that.driverRating,_that.vehicleType,_that.plateNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverMatchResultModel extends DriverMatchResultModel {
  const _DriverMatchResultModel({required this.trip, required this.driverId, required this.driverName, required this.fare, required this.driverRating, required this.vehicleType, required this.plateNumber}): super._();
  factory _DriverMatchResultModel.fromJson(Map<String, dynamic> json) => _$DriverMatchResultModelFromJson(json);

@override final  BidSessionTripModel trip;
@override final  String driverId;
@override final  String driverName;
@override final  double fare;
@override final  String? driverRating;
@override final  String vehicleType;
@override final  String plateNumber;

/// Create a copy of DriverMatchResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverMatchResultModelCopyWith<_DriverMatchResultModel> get copyWith => __$DriverMatchResultModelCopyWithImpl<_DriverMatchResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverMatchResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverMatchResultModel&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.fare, fare) || other.fare == fare)&&(identical(other.driverRating, driverRating) || other.driverRating == driverRating)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trip,driverId,driverName,fare,driverRating,vehicleType,plateNumber);

@override
String toString() {
  return 'DriverMatchResultModel(trip: $trip, driverId: $driverId, driverName: $driverName, fare: $fare, driverRating: $driverRating, vehicleType: $vehicleType, plateNumber: $plateNumber)';
}


}

/// @nodoc
abstract mixin class _$DriverMatchResultModelCopyWith<$Res> implements $DriverMatchResultModelCopyWith<$Res> {
  factory _$DriverMatchResultModelCopyWith(_DriverMatchResultModel value, $Res Function(_DriverMatchResultModel) _then) = __$DriverMatchResultModelCopyWithImpl;
@override @useResult
$Res call({
 BidSessionTripModel trip, String driverId, String driverName, double fare, String? driverRating, String vehicleType, String plateNumber
});


@override $BidSessionTripModelCopyWith<$Res> get trip;

}
/// @nodoc
class __$DriverMatchResultModelCopyWithImpl<$Res>
    implements _$DriverMatchResultModelCopyWith<$Res> {
  __$DriverMatchResultModelCopyWithImpl(this._self, this._then);

  final _DriverMatchResultModel _self;
  final $Res Function(_DriverMatchResultModel) _then;

/// Create a copy of DriverMatchResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trip = null,Object? driverId = null,Object? driverName = null,Object? fare = null,Object? driverRating = freezed,Object? vehicleType = null,Object? plateNumber = null,}) {
  return _then(_DriverMatchResultModel(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as BidSessionTripModel,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,fare: null == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as double,driverRating: freezed == driverRating ? _self.driverRating : driverRating // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of DriverMatchResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BidSessionTripModelCopyWith<$Res> get trip {
  
  return $BidSessionTripModelCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}

// dart format on

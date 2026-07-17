// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../ride_update_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RideUpdate {

@JsonKey(fromJson: RideStatus.fromString) RideStatus get status;@JsonKey(name: 'driver_id') String? get driverId;@JsonKey(name: 'driver_name', defaultValue: 'Driver') String get driverName;@JsonKey(name: 'plate_number', defaultValue: '—') String get vehiclePlate;@JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao') String get vehicleType;
/// Create a copy of RideUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RideUpdateCopyWith<RideUpdate> get copyWith => _$RideUpdateCopyWithImpl<RideUpdate>(this as RideUpdate, _$identity);

  /// Serializes this RideUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideUpdate&&(identical(other.status, status) || other.status == status)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,driverId,driverName,vehiclePlate,vehicleType);

@override
String toString() {
  return 'RideUpdate(status: $status, driverId: $driverId, driverName: $driverName, vehiclePlate: $vehiclePlate, vehicleType: $vehicleType)';
}


}

/// @nodoc
abstract mixin class $RideUpdateCopyWith<$Res>  {
  factory $RideUpdateCopyWith(RideUpdate value, $Res Function(RideUpdate) _then) = _$RideUpdateCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: RideStatus.fromString) RideStatus status,@JsonKey(name: 'driver_id') String? driverId,@JsonKey(name: 'driver_name', defaultValue: 'Driver') String driverName,@JsonKey(name: 'plate_number', defaultValue: '—') String vehiclePlate,@JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao') String vehicleType
});




}
/// @nodoc
class _$RideUpdateCopyWithImpl<$Res>
    implements $RideUpdateCopyWith<$Res> {
  _$RideUpdateCopyWithImpl(this._self, this._then);

  final RideUpdate _self;
  final $Res Function(RideUpdate) _then;

/// Create a copy of RideUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? driverId = freezed,Object? driverName = null,Object? vehiclePlate = null,Object? vehicleType = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RideStatus,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RideUpdate].
extension RideUpdatePatterns on RideUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RideUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RideUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RideUpdate value)  $default,){
final _that = this;
switch (_that) {
case _RideUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RideUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _RideUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: RideStatus.fromString)  RideStatus status, @JsonKey(name: 'driver_id')  String? driverId, @JsonKey(name: 'driver_name', defaultValue: 'Driver')  String driverName, @JsonKey(name: 'plate_number', defaultValue: '—')  String vehiclePlate, @JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao')  String vehicleType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RideUpdate() when $default != null:
return $default(_that.status,_that.driverId,_that.driverName,_that.vehiclePlate,_that.vehicleType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: RideStatus.fromString)  RideStatus status, @JsonKey(name: 'driver_id')  String? driverId, @JsonKey(name: 'driver_name', defaultValue: 'Driver')  String driverName, @JsonKey(name: 'plate_number', defaultValue: '—')  String vehiclePlate, @JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao')  String vehicleType)  $default,) {final _that = this;
switch (_that) {
case _RideUpdate():
return $default(_that.status,_that.driverId,_that.driverName,_that.vehiclePlate,_that.vehicleType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: RideStatus.fromString)  RideStatus status, @JsonKey(name: 'driver_id')  String? driverId, @JsonKey(name: 'driver_name', defaultValue: 'Driver')  String driverName, @JsonKey(name: 'plate_number', defaultValue: '—')  String vehiclePlate, @JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao')  String vehicleType)?  $default,) {final _that = this;
switch (_that) {
case _RideUpdate() when $default != null:
return $default(_that.status,_that.driverId,_that.driverName,_that.vehiclePlate,_that.vehicleType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RideUpdate implements RideUpdate {
  const _RideUpdate({@JsonKey(fromJson: RideStatus.fromString) required this.status, @JsonKey(name: 'driver_id') this.driverId, @JsonKey(name: 'driver_name', defaultValue: 'Driver') required this.driverName, @JsonKey(name: 'plate_number', defaultValue: '—') required this.vehiclePlate, @JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao') required this.vehicleType});
  factory _RideUpdate.fromJson(Map<String, dynamic> json) => _$RideUpdateFromJson(json);

@override@JsonKey(fromJson: RideStatus.fromString) final  RideStatus status;
@override@JsonKey(name: 'driver_id') final  String? driverId;
@override@JsonKey(name: 'driver_name', defaultValue: 'Driver') final  String driverName;
@override@JsonKey(name: 'plate_number', defaultValue: '—') final  String vehiclePlate;
@override@JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao') final  String vehicleType;

/// Create a copy of RideUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RideUpdateCopyWith<_RideUpdate> get copyWith => __$RideUpdateCopyWithImpl<_RideUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RideUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RideUpdate&&(identical(other.status, status) || other.status == status)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,driverId,driverName,vehiclePlate,vehicleType);

@override
String toString() {
  return 'RideUpdate(status: $status, driverId: $driverId, driverName: $driverName, vehiclePlate: $vehiclePlate, vehicleType: $vehicleType)';
}


}

/// @nodoc
abstract mixin class _$RideUpdateCopyWith<$Res> implements $RideUpdateCopyWith<$Res> {
  factory _$RideUpdateCopyWith(_RideUpdate value, $Res Function(_RideUpdate) _then) = __$RideUpdateCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: RideStatus.fromString) RideStatus status,@JsonKey(name: 'driver_id') String? driverId,@JsonKey(name: 'driver_name', defaultValue: 'Driver') String driverName,@JsonKey(name: 'plate_number', defaultValue: '—') String vehiclePlate,@JsonKey(name: 'vehicle_type', defaultValue: 'Bao Bao') String vehicleType
});




}
/// @nodoc
class __$RideUpdateCopyWithImpl<$Res>
    implements _$RideUpdateCopyWith<$Res> {
  __$RideUpdateCopyWithImpl(this._self, this._then);

  final _RideUpdate _self;
  final $Res Function(_RideUpdate) _then;

/// Create a copy of RideUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? driverId = freezed,Object? driverName = null,Object? vehiclePlate = null,Object? vehicleType = null,}) {
  return _then(_RideUpdate(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RideStatus,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

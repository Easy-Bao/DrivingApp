// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../ride_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RideHistoryModel {

 String get id; String get pickup; String get destination; double get pickupLat; double get pickupLng; double get destLat; double get destLng; String get date; String get price; String get status; String get driverId; String get driverName; String get vehiclePlate; String get vehicleType;
/// Create a copy of RideHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RideHistoryModelCopyWith<RideHistoryModel> get copyWith => _$RideHistoryModelCopyWithImpl<RideHistoryModel>(this as RideHistoryModel, _$identity);

  /// Serializes this RideHistoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.destLat, destLat) || other.destLat == destLat)&&(identical(other.destLng, destLng) || other.destLng == destLng)&&(identical(other.date, date) || other.date == date)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pickup,destination,pickupLat,pickupLng,destLat,destLng,date,price,status,driverId,driverName,vehiclePlate,vehicleType);

@override
String toString() {
  return 'RideHistoryModel(id: $id, pickup: $pickup, destination: $destination, pickupLat: $pickupLat, pickupLng: $pickupLng, destLat: $destLat, destLng: $destLng, date: $date, price: $price, status: $status, driverId: $driverId, driverName: $driverName, vehiclePlate: $vehiclePlate, vehicleType: $vehicleType)';
}


}

/// @nodoc
abstract mixin class $RideHistoryModelCopyWith<$Res>  {
  factory $RideHistoryModelCopyWith(RideHistoryModel value, $Res Function(RideHistoryModel) _then) = _$RideHistoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String pickup, String destination, double pickupLat, double pickupLng, double destLat, double destLng, String date, String price, String status, String driverId, String driverName, String vehiclePlate, String vehicleType
});




}
/// @nodoc
class _$RideHistoryModelCopyWithImpl<$Res>
    implements $RideHistoryModelCopyWith<$Res> {
  _$RideHistoryModelCopyWithImpl(this._self, this._then);

  final RideHistoryModel _self;
  final $Res Function(RideHistoryModel) _then;

/// Create a copy of RideHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pickup = null,Object? destination = null,Object? pickupLat = null,Object? pickupLng = null,Object? destLat = null,Object? destLng = null,Object? date = null,Object? price = null,Object? status = null,Object? driverId = null,Object? driverName = null,Object? vehiclePlate = null,Object? vehicleType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,pickupLat: null == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double,pickupLng: null == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double,destLat: null == destLat ? _self.destLat : destLat // ignore: cast_nullable_to_non_nullable
as double,destLng: null == destLng ? _self.destLng : destLng // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RideHistoryModel].
extension RideHistoryModelPatterns on RideHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RideHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RideHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RideHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _RideHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RideHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _RideHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pickup,  String destination,  double pickupLat,  double pickupLng,  double destLat,  double destLng,  String date,  String price,  String status,  String driverId,  String driverName,  String vehiclePlate,  String vehicleType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RideHistoryModel() when $default != null:
return $default(_that.id,_that.pickup,_that.destination,_that.pickupLat,_that.pickupLng,_that.destLat,_that.destLng,_that.date,_that.price,_that.status,_that.driverId,_that.driverName,_that.vehiclePlate,_that.vehicleType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pickup,  String destination,  double pickupLat,  double pickupLng,  double destLat,  double destLng,  String date,  String price,  String status,  String driverId,  String driverName,  String vehiclePlate,  String vehicleType)  $default,) {final _that = this;
switch (_that) {
case _RideHistoryModel():
return $default(_that.id,_that.pickup,_that.destination,_that.pickupLat,_that.pickupLng,_that.destLat,_that.destLng,_that.date,_that.price,_that.status,_that.driverId,_that.driverName,_that.vehiclePlate,_that.vehicleType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pickup,  String destination,  double pickupLat,  double pickupLng,  double destLat,  double destLng,  String date,  String price,  String status,  String driverId,  String driverName,  String vehiclePlate,  String vehicleType)?  $default,) {final _that = this;
switch (_that) {
case _RideHistoryModel() when $default != null:
return $default(_that.id,_that.pickup,_that.destination,_that.pickupLat,_that.pickupLng,_that.destLat,_that.destLng,_that.date,_that.price,_that.status,_that.driverId,_that.driverName,_that.vehiclePlate,_that.vehicleType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RideHistoryModel implements RideHistoryModel {
  const _RideHistoryModel({required this.id, required this.pickup, required this.destination, required this.pickupLat, required this.pickupLng, required this.destLat, required this.destLng, required this.date, required this.price, required this.status, required this.driverId, required this.driverName, required this.vehiclePlate, required this.vehicleType});
  factory _RideHistoryModel.fromJson(Map<String, dynamic> json) => _$RideHistoryModelFromJson(json);

@override final  String id;
@override final  String pickup;
@override final  String destination;
@override final  double pickupLat;
@override final  double pickupLng;
@override final  double destLat;
@override final  double destLng;
@override final  String date;
@override final  String price;
@override final  String status;
@override final  String driverId;
@override final  String driverName;
@override final  String vehiclePlate;
@override final  String vehicleType;

/// Create a copy of RideHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RideHistoryModelCopyWith<_RideHistoryModel> get copyWith => __$RideHistoryModelCopyWithImpl<_RideHistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RideHistoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RideHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.destLat, destLat) || other.destLat == destLat)&&(identical(other.destLng, destLng) || other.destLng == destLng)&&(identical(other.date, date) || other.date == date)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pickup,destination,pickupLat,pickupLng,destLat,destLng,date,price,status,driverId,driverName,vehiclePlate,vehicleType);

@override
String toString() {
  return 'RideHistoryModel(id: $id, pickup: $pickup, destination: $destination, pickupLat: $pickupLat, pickupLng: $pickupLng, destLat: $destLat, destLng: $destLng, date: $date, price: $price, status: $status, driverId: $driverId, driverName: $driverName, vehiclePlate: $vehiclePlate, vehicleType: $vehicleType)';
}


}

/// @nodoc
abstract mixin class _$RideHistoryModelCopyWith<$Res> implements $RideHistoryModelCopyWith<$Res> {
  factory _$RideHistoryModelCopyWith(_RideHistoryModel value, $Res Function(_RideHistoryModel) _then) = __$RideHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String pickup, String destination, double pickupLat, double pickupLng, double destLat, double destLng, String date, String price, String status, String driverId, String driverName, String vehiclePlate, String vehicleType
});




}
/// @nodoc
class __$RideHistoryModelCopyWithImpl<$Res>
    implements _$RideHistoryModelCopyWith<$Res> {
  __$RideHistoryModelCopyWithImpl(this._self, this._then);

  final _RideHistoryModel _self;
  final $Res Function(_RideHistoryModel) _then;

/// Create a copy of RideHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pickup = null,Object? destination = null,Object? pickupLat = null,Object? pickupLng = null,Object? destLat = null,Object? destLng = null,Object? date = null,Object? price = null,Object? status = null,Object? driverId = null,Object? driverName = null,Object? vehiclePlate = null,Object? vehicleType = null,}) {
  return _then(_RideHistoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,pickupLat: null == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double,pickupLng: null == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double,destLat: null == destLat ? _self.destLat : destLat // ignore: cast_nullable_to_non_nullable
as double,destLng: null == destLng ? _self.destLng : destLng // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

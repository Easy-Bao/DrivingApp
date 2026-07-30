// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../track_driver_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackDriverState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackDriverState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackDriverState()';
}


}

/// @nodoc
class $TrackDriverStateCopyWith<$Res>  {
$TrackDriverStateCopyWith(TrackDriverState _, $Res Function(TrackDriverState) __);
}


/// Adds pattern-matching-related methods to [TrackDriverState].
extension TrackDriverStatePatterns on TrackDriverState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrackDriverInitial value)?  initial,TResult Function( TrackDriverInProgress value)?  inProgress,TResult Function( TrackDriverCompleted value)?  completed,TResult Function( TrackDriverCanceled value)?  canceled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrackDriverInitial() when initial != null:
return initial(_that);case TrackDriverInProgress() when inProgress != null:
return inProgress(_that);case TrackDriverCompleted() when completed != null:
return completed(_that);case TrackDriverCanceled() when canceled != null:
return canceled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrackDriverInitial value)  initial,required TResult Function( TrackDriverInProgress value)  inProgress,required TResult Function( TrackDriverCompleted value)  completed,required TResult Function( TrackDriverCanceled value)  canceled,}){
final _that = this;
switch (_that) {
case TrackDriverInitial():
return initial(_that);case TrackDriverInProgress():
return inProgress(_that);case TrackDriverCompleted():
return completed(_that);case TrackDriverCanceled():
return canceled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrackDriverInitial value)?  initial,TResult? Function( TrackDriverInProgress value)?  inProgress,TResult? Function( TrackDriverCompleted value)?  completed,TResult? Function( TrackDriverCanceled value)?  canceled,}){
final _that = this;
switch (_that) {
case TrackDriverInitial() when initial != null:
return initial(_that);case TrackDriverInProgress() when inProgress != null:
return inProgress(_that);case TrackDriverCompleted() when completed != null:
return completed(_that);case TrackDriverCanceled() when canceled != null:
return canceled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( double driverLat,  double driverLng,  double progress,  String eta,  String driverName,  String vehiclePlate,  String vehicleType,  List<List<double>>? routePoints)?  inProgress,TResult Function( String driverId,  String driverName)?  completed,TResult Function()?  canceled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrackDriverInitial() when initial != null:
return initial();case TrackDriverInProgress() when inProgress != null:
return inProgress(_that.driverLat,_that.driverLng,_that.progress,_that.eta,_that.driverName,_that.vehiclePlate,_that.vehicleType,_that.routePoints);case TrackDriverCompleted() when completed != null:
return completed(_that.driverId,_that.driverName);case TrackDriverCanceled() when canceled != null:
return canceled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( double driverLat,  double driverLng,  double progress,  String eta,  String driverName,  String vehiclePlate,  String vehicleType,  List<List<double>>? routePoints)  inProgress,required TResult Function( String driverId,  String driverName)  completed,required TResult Function()  canceled,}) {final _that = this;
switch (_that) {
case TrackDriverInitial():
return initial();case TrackDriverInProgress():
return inProgress(_that.driverLat,_that.driverLng,_that.progress,_that.eta,_that.driverName,_that.vehiclePlate,_that.vehicleType,_that.routePoints);case TrackDriverCompleted():
return completed(_that.driverId,_that.driverName);case TrackDriverCanceled():
return canceled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( double driverLat,  double driverLng,  double progress,  String eta,  String driverName,  String vehiclePlate,  String vehicleType,  List<List<double>>? routePoints)?  inProgress,TResult? Function( String driverId,  String driverName)?  completed,TResult? Function()?  canceled,}) {final _that = this;
switch (_that) {
case TrackDriverInitial() when initial != null:
return initial();case TrackDriverInProgress() when inProgress != null:
return inProgress(_that.driverLat,_that.driverLng,_that.progress,_that.eta,_that.driverName,_that.vehiclePlate,_that.vehicleType,_that.routePoints);case TrackDriverCompleted() when completed != null:
return completed(_that.driverId,_that.driverName);case TrackDriverCanceled() when canceled != null:
return canceled();case _:
  return null;

}
}

}

/// @nodoc


class TrackDriverInitial implements TrackDriverState {
  const TrackDriverInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackDriverInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackDriverState.initial()';
}


}




/// @nodoc


class TrackDriverInProgress implements TrackDriverState {
  const TrackDriverInProgress({required this.driverLat, required this.driverLng, required this.progress, required this.eta, required this.driverName, required this.vehiclePlate, required this.vehicleType, final  List<List<double>>? routePoints}): _routePoints = routePoints;
  

 final  double driverLat;
 final  double driverLng;
 final  double progress;
 final  String eta;
 final  String driverName;
 final  String vehiclePlate;
 final  String vehicleType;
 final  List<List<double>>? _routePoints;
 List<List<double>>? get routePoints {
  final value = _routePoints;
  if (value == null) return null;
  if (_routePoints is EqualUnmodifiableListView) return _routePoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TrackDriverState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackDriverInProgressCopyWith<TrackDriverInProgress> get copyWith => _$TrackDriverInProgressCopyWithImpl<TrackDriverInProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackDriverInProgress&&(identical(other.driverLat, driverLat) || other.driverLat == driverLat)&&(identical(other.driverLng, driverLng) || other.driverLng == driverLng)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.eta, eta) || other.eta == eta)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&const DeepCollectionEquality().equals(other._routePoints, _routePoints));
}


@override
int get hashCode => Object.hash(runtimeType,driverLat,driverLng,progress,eta,driverName,vehiclePlate,vehicleType,const DeepCollectionEquality().hash(_routePoints));

@override
String toString() {
  return 'TrackDriverState.inProgress(driverLat: $driverLat, driverLng: $driverLng, progress: $progress, eta: $eta, driverName: $driverName, vehiclePlate: $vehiclePlate, vehicleType: $vehicleType, routePoints: $routePoints)';
}


}

/// @nodoc
abstract mixin class $TrackDriverInProgressCopyWith<$Res> implements $TrackDriverStateCopyWith<$Res> {
  factory $TrackDriverInProgressCopyWith(TrackDriverInProgress value, $Res Function(TrackDriverInProgress) _then) = _$TrackDriverInProgressCopyWithImpl;
@useResult
$Res call({
 double driverLat, double driverLng, double progress, String eta, String driverName, String vehiclePlate, String vehicleType, List<List<double>>? routePoints
});




}
/// @nodoc
class _$TrackDriverInProgressCopyWithImpl<$Res>
    implements $TrackDriverInProgressCopyWith<$Res> {
  _$TrackDriverInProgressCopyWithImpl(this._self, this._then);

  final TrackDriverInProgress _self;
  final $Res Function(TrackDriverInProgress) _then;

/// Create a copy of TrackDriverState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? driverLat = null,Object? driverLng = null,Object? progress = null,Object? eta = null,Object? driverName = null,Object? vehiclePlate = null,Object? vehicleType = null,Object? routePoints = freezed,}) {
  return _then(TrackDriverInProgress(
driverLat: null == driverLat ? _self.driverLat : driverLat // ignore: cast_nullable_to_non_nullable
as double,driverLng: null == driverLng ? _self.driverLng : driverLng // ignore: cast_nullable_to_non_nullable
as double,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,eta: null == eta ? _self.eta : eta // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,routePoints: freezed == routePoints ? _self._routePoints : routePoints // ignore: cast_nullable_to_non_nullable
as List<List<double>>?,
  ));
}


}

/// @nodoc


class TrackDriverCompleted implements TrackDriverState {
  const TrackDriverCompleted({required this.driverId, required this.driverName});
  

 final  String driverId;
 final  String driverName;

/// Create a copy of TrackDriverState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackDriverCompletedCopyWith<TrackDriverCompleted> get copyWith => _$TrackDriverCompletedCopyWithImpl<TrackDriverCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackDriverCompleted&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName));
}


@override
int get hashCode => Object.hash(runtimeType,driverId,driverName);

@override
String toString() {
  return 'TrackDriverState.completed(driverId: $driverId, driverName: $driverName)';
}


}

/// @nodoc
abstract mixin class $TrackDriverCompletedCopyWith<$Res> implements $TrackDriverStateCopyWith<$Res> {
  factory $TrackDriverCompletedCopyWith(TrackDriverCompleted value, $Res Function(TrackDriverCompleted) _then) = _$TrackDriverCompletedCopyWithImpl;
@useResult
$Res call({
 String driverId, String driverName
});




}
/// @nodoc
class _$TrackDriverCompletedCopyWithImpl<$Res>
    implements $TrackDriverCompletedCopyWith<$Res> {
  _$TrackDriverCompletedCopyWithImpl(this._self, this._then);

  final TrackDriverCompleted _self;
  final $Res Function(TrackDriverCompleted) _then;

/// Create a copy of TrackDriverState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? driverName = null,}) {
  return _then(TrackDriverCompleted(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TrackDriverCanceled implements TrackDriverState {
  const TrackDriverCanceled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackDriverCanceled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackDriverState.canceled()';
}


}




// dart format on

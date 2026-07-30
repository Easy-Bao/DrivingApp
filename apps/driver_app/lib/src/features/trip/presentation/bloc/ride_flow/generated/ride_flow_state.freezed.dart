// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../ride_flow_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RideFlowState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideFlowState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RideFlowState()';
}


}

/// @nodoc
class $RideFlowStateCopyWith<$Res>  {
$RideFlowStateCopyWith(RideFlowState _, $Res Function(RideFlowState) __);
}


/// Adds pattern-matching-related methods to [RideFlowState].
extension RideFlowStatePatterns on RideFlowState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RideFlowInitial value)?  initial,TResult Function( RideFlowEnRoutePickup value)?  enRoutePickup,TResult Function( RideFlowWaitingPassenger value)?  waitingPassenger,TResult Function( RideFlowInTransit value)?  inTransit,TResult Function( RideFlowComplete value)?  complete,TResult Function( RideFlowError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RideFlowInitial() when initial != null:
return initial(_that);case RideFlowEnRoutePickup() when enRoutePickup != null:
return enRoutePickup(_that);case RideFlowWaitingPassenger() when waitingPassenger != null:
return waitingPassenger(_that);case RideFlowInTransit() when inTransit != null:
return inTransit(_that);case RideFlowComplete() when complete != null:
return complete(_that);case RideFlowError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RideFlowInitial value)  initial,required TResult Function( RideFlowEnRoutePickup value)  enRoutePickup,required TResult Function( RideFlowWaitingPassenger value)  waitingPassenger,required TResult Function( RideFlowInTransit value)  inTransit,required TResult Function( RideFlowComplete value)  complete,required TResult Function( RideFlowError value)  error,}){
final _that = this;
switch (_that) {
case RideFlowInitial():
return initial(_that);case RideFlowEnRoutePickup():
return enRoutePickup(_that);case RideFlowWaitingPassenger():
return waitingPassenger(_that);case RideFlowInTransit():
return inTransit(_that);case RideFlowComplete():
return complete(_that);case RideFlowError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RideFlowInitial value)?  initial,TResult? Function( RideFlowEnRoutePickup value)?  enRoutePickup,TResult? Function( RideFlowWaitingPassenger value)?  waitingPassenger,TResult? Function( RideFlowInTransit value)?  inTransit,TResult? Function( RideFlowComplete value)?  complete,TResult? Function( RideFlowError value)?  error,}){
final _that = this;
switch (_that) {
case RideFlowInitial() when initial != null:
return initial(_that);case RideFlowEnRoutePickup() when enRoutePickup != null:
return enRoutePickup(_that);case RideFlowWaitingPassenger() when waitingPassenger != null:
return waitingPassenger(_that);case RideFlowInTransit() when inTransit != null:
return inTransit(_that);case RideFlowComplete() when complete != null:
return complete(_that);case RideFlowError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String passengerName,  double pickupLat,  double pickupLng)?  enRoutePickup,TResult Function( String passengerName,  int waitTimeSeconds)?  waitingPassenger,TResult Function( String passengerName,  double destLat,  double destLng,  double distanceKm)?  inTransit,TResult Function( double fare)?  complete,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RideFlowInitial() when initial != null:
return initial();case RideFlowEnRoutePickup() when enRoutePickup != null:
return enRoutePickup(_that.passengerName,_that.pickupLat,_that.pickupLng);case RideFlowWaitingPassenger() when waitingPassenger != null:
return waitingPassenger(_that.passengerName,_that.waitTimeSeconds);case RideFlowInTransit() when inTransit != null:
return inTransit(_that.passengerName,_that.destLat,_that.destLng,_that.distanceKm);case RideFlowComplete() when complete != null:
return complete(_that.fare);case RideFlowError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String passengerName,  double pickupLat,  double pickupLng)  enRoutePickup,required TResult Function( String passengerName,  int waitTimeSeconds)  waitingPassenger,required TResult Function( String passengerName,  double destLat,  double destLng,  double distanceKm)  inTransit,required TResult Function( double fare)  complete,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case RideFlowInitial():
return initial();case RideFlowEnRoutePickup():
return enRoutePickup(_that.passengerName,_that.pickupLat,_that.pickupLng);case RideFlowWaitingPassenger():
return waitingPassenger(_that.passengerName,_that.waitTimeSeconds);case RideFlowInTransit():
return inTransit(_that.passengerName,_that.destLat,_that.destLng,_that.distanceKm);case RideFlowComplete():
return complete(_that.fare);case RideFlowError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String passengerName,  double pickupLat,  double pickupLng)?  enRoutePickup,TResult? Function( String passengerName,  int waitTimeSeconds)?  waitingPassenger,TResult? Function( String passengerName,  double destLat,  double destLng,  double distanceKm)?  inTransit,TResult? Function( double fare)?  complete,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case RideFlowInitial() when initial != null:
return initial();case RideFlowEnRoutePickup() when enRoutePickup != null:
return enRoutePickup(_that.passengerName,_that.pickupLat,_that.pickupLng);case RideFlowWaitingPassenger() when waitingPassenger != null:
return waitingPassenger(_that.passengerName,_that.waitTimeSeconds);case RideFlowInTransit() when inTransit != null:
return inTransit(_that.passengerName,_that.destLat,_that.destLng,_that.distanceKm);case RideFlowComplete() when complete != null:
return complete(_that.fare);case RideFlowError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class RideFlowInitial implements RideFlowState {
  const RideFlowInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideFlowInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RideFlowState.initial()';
}


}




/// @nodoc


class RideFlowEnRoutePickup implements RideFlowState {
  const RideFlowEnRoutePickup({required this.passengerName, required this.pickupLat, required this.pickupLng});
  

 final  String passengerName;
 final  double pickupLat;
 final  double pickupLng;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RideFlowEnRoutePickupCopyWith<RideFlowEnRoutePickup> get copyWith => _$RideFlowEnRoutePickupCopyWithImpl<RideFlowEnRoutePickup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideFlowEnRoutePickup&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng));
}


@override
int get hashCode => Object.hash(runtimeType,passengerName,pickupLat,pickupLng);

@override
String toString() {
  return 'RideFlowState.enRoutePickup(passengerName: $passengerName, pickupLat: $pickupLat, pickupLng: $pickupLng)';
}


}

/// @nodoc
abstract mixin class $RideFlowEnRoutePickupCopyWith<$Res> implements $RideFlowStateCopyWith<$Res> {
  factory $RideFlowEnRoutePickupCopyWith(RideFlowEnRoutePickup value, $Res Function(RideFlowEnRoutePickup) _then) = _$RideFlowEnRoutePickupCopyWithImpl;
@useResult
$Res call({
 String passengerName, double pickupLat, double pickupLng
});




}
/// @nodoc
class _$RideFlowEnRoutePickupCopyWithImpl<$Res>
    implements $RideFlowEnRoutePickupCopyWith<$Res> {
  _$RideFlowEnRoutePickupCopyWithImpl(this._self, this._then);

  final RideFlowEnRoutePickup _self;
  final $Res Function(RideFlowEnRoutePickup) _then;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? passengerName = null,Object? pickupLat = null,Object? pickupLng = null,}) {
  return _then(RideFlowEnRoutePickup(
passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,pickupLat: null == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double,pickupLng: null == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class RideFlowWaitingPassenger implements RideFlowState {
  const RideFlowWaitingPassenger({required this.passengerName, required this.waitTimeSeconds});
  

 final  String passengerName;
 final  int waitTimeSeconds;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RideFlowWaitingPassengerCopyWith<RideFlowWaitingPassenger> get copyWith => _$RideFlowWaitingPassengerCopyWithImpl<RideFlowWaitingPassenger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideFlowWaitingPassenger&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.waitTimeSeconds, waitTimeSeconds) || other.waitTimeSeconds == waitTimeSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,passengerName,waitTimeSeconds);

@override
String toString() {
  return 'RideFlowState.waitingPassenger(passengerName: $passengerName, waitTimeSeconds: $waitTimeSeconds)';
}


}

/// @nodoc
abstract mixin class $RideFlowWaitingPassengerCopyWith<$Res> implements $RideFlowStateCopyWith<$Res> {
  factory $RideFlowWaitingPassengerCopyWith(RideFlowWaitingPassenger value, $Res Function(RideFlowWaitingPassenger) _then) = _$RideFlowWaitingPassengerCopyWithImpl;
@useResult
$Res call({
 String passengerName, int waitTimeSeconds
});




}
/// @nodoc
class _$RideFlowWaitingPassengerCopyWithImpl<$Res>
    implements $RideFlowWaitingPassengerCopyWith<$Res> {
  _$RideFlowWaitingPassengerCopyWithImpl(this._self, this._then);

  final RideFlowWaitingPassenger _self;
  final $Res Function(RideFlowWaitingPassenger) _then;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? passengerName = null,Object? waitTimeSeconds = null,}) {
  return _then(RideFlowWaitingPassenger(
passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,waitTimeSeconds: null == waitTimeSeconds ? _self.waitTimeSeconds : waitTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RideFlowInTransit implements RideFlowState {
  const RideFlowInTransit({required this.passengerName, required this.destLat, required this.destLng, required this.distanceKm});
  

 final  String passengerName;
 final  double destLat;
 final  double destLng;
 final  double distanceKm;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RideFlowInTransitCopyWith<RideFlowInTransit> get copyWith => _$RideFlowInTransitCopyWithImpl<RideFlowInTransit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideFlowInTransit&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.destLat, destLat) || other.destLat == destLat)&&(identical(other.destLng, destLng) || other.destLng == destLng)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm));
}


@override
int get hashCode => Object.hash(runtimeType,passengerName,destLat,destLng,distanceKm);

@override
String toString() {
  return 'RideFlowState.inTransit(passengerName: $passengerName, destLat: $destLat, destLng: $destLng, distanceKm: $distanceKm)';
}


}

/// @nodoc
abstract mixin class $RideFlowInTransitCopyWith<$Res> implements $RideFlowStateCopyWith<$Res> {
  factory $RideFlowInTransitCopyWith(RideFlowInTransit value, $Res Function(RideFlowInTransit) _then) = _$RideFlowInTransitCopyWithImpl;
@useResult
$Res call({
 String passengerName, double destLat, double destLng, double distanceKm
});




}
/// @nodoc
class _$RideFlowInTransitCopyWithImpl<$Res>
    implements $RideFlowInTransitCopyWith<$Res> {
  _$RideFlowInTransitCopyWithImpl(this._self, this._then);

  final RideFlowInTransit _self;
  final $Res Function(RideFlowInTransit) _then;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? passengerName = null,Object? destLat = null,Object? destLng = null,Object? distanceKm = null,}) {
  return _then(RideFlowInTransit(
passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,destLat: null == destLat ? _self.destLat : destLat // ignore: cast_nullable_to_non_nullable
as double,destLng: null == destLng ? _self.destLng : destLng // ignore: cast_nullable_to_non_nullable
as double,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class RideFlowComplete implements RideFlowState {
  const RideFlowComplete({required this.fare});
  

 final  double fare;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RideFlowCompleteCopyWith<RideFlowComplete> get copyWith => _$RideFlowCompleteCopyWithImpl<RideFlowComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideFlowComplete&&(identical(other.fare, fare) || other.fare == fare));
}


@override
int get hashCode => Object.hash(runtimeType,fare);

@override
String toString() {
  return 'RideFlowState.complete(fare: $fare)';
}


}

/// @nodoc
abstract mixin class $RideFlowCompleteCopyWith<$Res> implements $RideFlowStateCopyWith<$Res> {
  factory $RideFlowCompleteCopyWith(RideFlowComplete value, $Res Function(RideFlowComplete) _then) = _$RideFlowCompleteCopyWithImpl;
@useResult
$Res call({
 double fare
});




}
/// @nodoc
class _$RideFlowCompleteCopyWithImpl<$Res>
    implements $RideFlowCompleteCopyWith<$Res> {
  _$RideFlowCompleteCopyWithImpl(this._self, this._then);

  final RideFlowComplete _self;
  final $Res Function(RideFlowComplete) _then;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fare = null,}) {
  return _then(RideFlowComplete(
fare: null == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class RideFlowError implements RideFlowState {
  const RideFlowError(this.message);
  

 final  String message;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RideFlowErrorCopyWith<RideFlowError> get copyWith => _$RideFlowErrorCopyWithImpl<RideFlowError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RideFlowError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'RideFlowState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $RideFlowErrorCopyWith<$Res> implements $RideFlowStateCopyWith<$Res> {
  factory $RideFlowErrorCopyWith(RideFlowError value, $Res Function(RideFlowError) _then) = _$RideFlowErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$RideFlowErrorCopyWithImpl<$Res>
    implements $RideFlowErrorCopyWith<$Res> {
  _$RideFlowErrorCopyWithImpl(this._self, this._then);

  final RideFlowError _self;
  final $Res Function(RideFlowError) _then;

/// Create a copy of RideFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(RideFlowError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

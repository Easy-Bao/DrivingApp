// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../route_sequence_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteSequenceResult {

 List<Waypoint> get optimalSequence; double get totalDistanceKm;
/// Create a copy of RouteSequenceResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteSequenceResultCopyWith<RouteSequenceResult> get copyWith => _$RouteSequenceResultCopyWithImpl<RouteSequenceResult>(this as RouteSequenceResult, _$identity);

  /// Serializes this RouteSequenceResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteSequenceResult&&const DeepCollectionEquality().equals(other.optimalSequence, optimalSequence)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(optimalSequence),totalDistanceKm);

@override
String toString() {
  return 'RouteSequenceResult(optimalSequence: $optimalSequence, totalDistanceKm: $totalDistanceKm)';
}


}

/// @nodoc
abstract mixin class $RouteSequenceResultCopyWith<$Res>  {
  factory $RouteSequenceResultCopyWith(RouteSequenceResult value, $Res Function(RouteSequenceResult) _then) = _$RouteSequenceResultCopyWithImpl;
@useResult
$Res call({
 List<Waypoint> optimalSequence, double totalDistanceKm
});




}
/// @nodoc
class _$RouteSequenceResultCopyWithImpl<$Res>
    implements $RouteSequenceResultCopyWith<$Res> {
  _$RouteSequenceResultCopyWithImpl(this._self, this._then);

  final RouteSequenceResult _self;
  final $Res Function(RouteSequenceResult) _then;

/// Create a copy of RouteSequenceResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? optimalSequence = null,Object? totalDistanceKm = null,}) {
  return _then(_self.copyWith(
optimalSequence: null == optimalSequence ? _self.optimalSequence : optimalSequence // ignore: cast_nullable_to_non_nullable
as List<Waypoint>,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteSequenceResult].
extension RouteSequenceResultPatterns on RouteSequenceResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteSequenceResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteSequenceResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteSequenceResult value)  $default,){
final _that = this;
switch (_that) {
case _RouteSequenceResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteSequenceResult value)?  $default,){
final _that = this;
switch (_that) {
case _RouteSequenceResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Waypoint> optimalSequence,  double totalDistanceKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteSequenceResult() when $default != null:
return $default(_that.optimalSequence,_that.totalDistanceKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Waypoint> optimalSequence,  double totalDistanceKm)  $default,) {final _that = this;
switch (_that) {
case _RouteSequenceResult():
return $default(_that.optimalSequence,_that.totalDistanceKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Waypoint> optimalSequence,  double totalDistanceKm)?  $default,) {final _that = this;
switch (_that) {
case _RouteSequenceResult() when $default != null:
return $default(_that.optimalSequence,_that.totalDistanceKm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteSequenceResult implements RouteSequenceResult {
  const _RouteSequenceResult({required final  List<Waypoint> optimalSequence, required this.totalDistanceKm}): _optimalSequence = optimalSequence;
  factory _RouteSequenceResult.fromJson(Map<String, dynamic> json) => _$RouteSequenceResultFromJson(json);

 final  List<Waypoint> _optimalSequence;
@override List<Waypoint> get optimalSequence {
  if (_optimalSequence is EqualUnmodifiableListView) return _optimalSequence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_optimalSequence);
}

@override final  double totalDistanceKm;

/// Create a copy of RouteSequenceResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteSequenceResultCopyWith<_RouteSequenceResult> get copyWith => __$RouteSequenceResultCopyWithImpl<_RouteSequenceResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteSequenceResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteSequenceResult&&const DeepCollectionEquality().equals(other._optimalSequence, _optimalSequence)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_optimalSequence),totalDistanceKm);

@override
String toString() {
  return 'RouteSequenceResult(optimalSequence: $optimalSequence, totalDistanceKm: $totalDistanceKm)';
}


}

/// @nodoc
abstract mixin class _$RouteSequenceResultCopyWith<$Res> implements $RouteSequenceResultCopyWith<$Res> {
  factory _$RouteSequenceResultCopyWith(_RouteSequenceResult value, $Res Function(_RouteSequenceResult) _then) = __$RouteSequenceResultCopyWithImpl;
@override @useResult
$Res call({
 List<Waypoint> optimalSequence, double totalDistanceKm
});




}
/// @nodoc
class __$RouteSequenceResultCopyWithImpl<$Res>
    implements _$RouteSequenceResultCopyWith<$Res> {
  __$RouteSequenceResultCopyWithImpl(this._self, this._then);

  final _RouteSequenceResult _self;
  final $Res Function(_RouteSequenceResult) _then;

/// Create a copy of RouteSequenceResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? optimalSequence = null,Object? totalDistanceKm = null,}) {
  return _then(_RouteSequenceResult(
optimalSequence: null == optimalSequence ? _self._optimalSequence : optimalSequence // ignore: cast_nullable_to_non_nullable
as List<Waypoint>,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

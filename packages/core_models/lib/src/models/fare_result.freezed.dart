// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fare_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FareResult {

 double get baseFare; double get distanceCharge; double get timeCharge; double get surgeCharge; double get totalFare;
/// Create a copy of FareResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FareResultCopyWith<FareResult> get copyWith => _$FareResultCopyWithImpl<FareResult>(this as FareResult, _$identity);

  /// Serializes this FareResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FareResult&&(identical(other.baseFare, baseFare) || other.baseFare == baseFare)&&(identical(other.distanceCharge, distanceCharge) || other.distanceCharge == distanceCharge)&&(identical(other.timeCharge, timeCharge) || other.timeCharge == timeCharge)&&(identical(other.surgeCharge, surgeCharge) || other.surgeCharge == surgeCharge)&&(identical(other.totalFare, totalFare) || other.totalFare == totalFare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseFare,distanceCharge,timeCharge,surgeCharge,totalFare);

@override
String toString() {
  return 'FareResult(baseFare: $baseFare, distanceCharge: $distanceCharge, timeCharge: $timeCharge, surgeCharge: $surgeCharge, totalFare: $totalFare)';
}


}

/// @nodoc
abstract mixin class $FareResultCopyWith<$Res>  {
  factory $FareResultCopyWith(FareResult value, $Res Function(FareResult) _then) = _$FareResultCopyWithImpl;
@useResult
$Res call({
 double baseFare, double distanceCharge, double timeCharge, double surgeCharge, double totalFare
});




}
/// @nodoc
class _$FareResultCopyWithImpl<$Res>
    implements $FareResultCopyWith<$Res> {
  _$FareResultCopyWithImpl(this._self, this._then);

  final FareResult _self;
  final $Res Function(FareResult) _then;

/// Create a copy of FareResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseFare = null,Object? distanceCharge = null,Object? timeCharge = null,Object? surgeCharge = null,Object? totalFare = null,}) {
  return _then(_self.copyWith(
baseFare: null == baseFare ? _self.baseFare : baseFare // ignore: cast_nullable_to_non_nullable
as double,distanceCharge: null == distanceCharge ? _self.distanceCharge : distanceCharge // ignore: cast_nullable_to_non_nullable
as double,timeCharge: null == timeCharge ? _self.timeCharge : timeCharge // ignore: cast_nullable_to_non_nullable
as double,surgeCharge: null == surgeCharge ? _self.surgeCharge : surgeCharge // ignore: cast_nullable_to_non_nullable
as double,totalFare: null == totalFare ? _self.totalFare : totalFare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [FareResult].
extension FareResultPatterns on FareResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FareResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FareResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FareResult value)  $default,){
final _that = this;
switch (_that) {
case _FareResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FareResult value)?  $default,){
final _that = this;
switch (_that) {
case _FareResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double baseFare,  double distanceCharge,  double timeCharge,  double surgeCharge,  double totalFare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FareResult() when $default != null:
return $default(_that.baseFare,_that.distanceCharge,_that.timeCharge,_that.surgeCharge,_that.totalFare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double baseFare,  double distanceCharge,  double timeCharge,  double surgeCharge,  double totalFare)  $default,) {final _that = this;
switch (_that) {
case _FareResult():
return $default(_that.baseFare,_that.distanceCharge,_that.timeCharge,_that.surgeCharge,_that.totalFare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double baseFare,  double distanceCharge,  double timeCharge,  double surgeCharge,  double totalFare)?  $default,) {final _that = this;
switch (_that) {
case _FareResult() when $default != null:
return $default(_that.baseFare,_that.distanceCharge,_that.timeCharge,_that.surgeCharge,_that.totalFare);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FareResult implements FareResult {
  const _FareResult({required this.baseFare, required this.distanceCharge, required this.timeCharge, required this.surgeCharge, required this.totalFare});
  factory _FareResult.fromJson(Map<String, dynamic> json) => _$FareResultFromJson(json);

@override final  double baseFare;
@override final  double distanceCharge;
@override final  double timeCharge;
@override final  double surgeCharge;
@override final  double totalFare;

/// Create a copy of FareResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FareResultCopyWith<_FareResult> get copyWith => __$FareResultCopyWithImpl<_FareResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FareResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FareResult&&(identical(other.baseFare, baseFare) || other.baseFare == baseFare)&&(identical(other.distanceCharge, distanceCharge) || other.distanceCharge == distanceCharge)&&(identical(other.timeCharge, timeCharge) || other.timeCharge == timeCharge)&&(identical(other.surgeCharge, surgeCharge) || other.surgeCharge == surgeCharge)&&(identical(other.totalFare, totalFare) || other.totalFare == totalFare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseFare,distanceCharge,timeCharge,surgeCharge,totalFare);

@override
String toString() {
  return 'FareResult(baseFare: $baseFare, distanceCharge: $distanceCharge, timeCharge: $timeCharge, surgeCharge: $surgeCharge, totalFare: $totalFare)';
}


}

/// @nodoc
abstract mixin class _$FareResultCopyWith<$Res> implements $FareResultCopyWith<$Res> {
  factory _$FareResultCopyWith(_FareResult value, $Res Function(_FareResult) _then) = __$FareResultCopyWithImpl;
@override @useResult
$Res call({
 double baseFare, double distanceCharge, double timeCharge, double surgeCharge, double totalFare
});




}
/// @nodoc
class __$FareResultCopyWithImpl<$Res>
    implements _$FareResultCopyWith<$Res> {
  __$FareResultCopyWithImpl(this._self, this._then);

  final _FareResult _self;
  final $Res Function(_FareResult) _then;

/// Create a copy of FareResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseFare = null,Object? distanceCharge = null,Object? timeCharge = null,Object? surgeCharge = null,Object? totalFare = null,}) {
  return _then(_FareResult(
baseFare: null == baseFare ? _self.baseFare : baseFare // ignore: cast_nullable_to_non_nullable
as double,distanceCharge: null == distanceCharge ? _self.distanceCharge : distanceCharge // ignore: cast_nullable_to_non_nullable
as double,timeCharge: null == timeCharge ? _self.timeCharge : timeCharge // ignore: cast_nullable_to_non_nullable
as double,surgeCharge: null == surgeCharge ? _self.surgeCharge : surgeCharge // ignore: cast_nullable_to_non_nullable
as double,totalFare: null == totalFare ? _self.totalFare : totalFare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

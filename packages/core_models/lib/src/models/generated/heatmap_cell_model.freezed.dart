// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../heatmap_cell_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HeatmapCell {

 double get lat; double get lng; double get intensity;
/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeatmapCellCopyWith<HeatmapCell> get copyWith => _$HeatmapCellCopyWithImpl<HeatmapCell>(this as HeatmapCell, _$identity);

  /// Serializes this HeatmapCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeatmapCell&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,intensity);

@override
String toString() {
  return 'HeatmapCell(lat: $lat, lng: $lng, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $HeatmapCellCopyWith<$Res>  {
  factory $HeatmapCellCopyWith(HeatmapCell value, $Res Function(HeatmapCell) _then) = _$HeatmapCellCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, double intensity
});




}
/// @nodoc
class _$HeatmapCellCopyWithImpl<$Res>
    implements $HeatmapCellCopyWith<$Res> {
  _$HeatmapCellCopyWithImpl(this._self, this._then);

  final HeatmapCell _self;
  final $Res Function(HeatmapCell) _then;

/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? intensity = null,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [HeatmapCell].
extension HeatmapCellPatterns on HeatmapCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeatmapCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeatmapCell value)  $default,){
final _that = this;
switch (_that) {
case _HeatmapCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeatmapCell value)?  $default,){
final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  double intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
return $default(_that.lat,_that.lng,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  double intensity)  $default,) {final _that = this;
switch (_that) {
case _HeatmapCell():
return $default(_that.lat,_that.lng,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  double intensity)?  $default,) {final _that = this;
switch (_that) {
case _HeatmapCell() when $default != null:
return $default(_that.lat,_that.lng,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HeatmapCell implements HeatmapCell {
  const _HeatmapCell({required this.lat, required this.lng, required this.intensity});
  factory _HeatmapCell.fromJson(Map<String, dynamic> json) => _$HeatmapCellFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  double intensity;

/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeatmapCellCopyWith<_HeatmapCell> get copyWith => __$HeatmapCellCopyWithImpl<_HeatmapCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HeatmapCellToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeatmapCell&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,intensity);

@override
String toString() {
  return 'HeatmapCell(lat: $lat, lng: $lng, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$HeatmapCellCopyWith<$Res> implements $HeatmapCellCopyWith<$Res> {
  factory _$HeatmapCellCopyWith(_HeatmapCell value, $Res Function(_HeatmapCell) _then) = __$HeatmapCellCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, double intensity
});




}
/// @nodoc
class __$HeatmapCellCopyWithImpl<$Res>
    implements _$HeatmapCellCopyWith<$Res> {
  __$HeatmapCellCopyWithImpl(this._self, this._then);

  final _HeatmapCell _self;
  final $Res Function(_HeatmapCell) _then;

/// Create a copy of HeatmapCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? intensity = null,}) {
  return _then(_HeatmapCell(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

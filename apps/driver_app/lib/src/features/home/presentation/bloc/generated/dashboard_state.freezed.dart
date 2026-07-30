// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../dashboard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DashboardState {

 bool get isOnline; bool get isLoadingStats; bool get isLoadingHeatmap; double get todayEarnings; int get todayTrips; double get hoursOnline; List<HeatmapCell> get surgeCells; String? get errorMessage;
/// Create a copy of DashboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardStateCopyWith<DashboardState> get copyWith => _$DashboardStateCopyWithImpl<DashboardState>(this as DashboardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardState&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.isLoadingStats, isLoadingStats) || other.isLoadingStats == isLoadingStats)&&(identical(other.isLoadingHeatmap, isLoadingHeatmap) || other.isLoadingHeatmap == isLoadingHeatmap)&&(identical(other.todayEarnings, todayEarnings) || other.todayEarnings == todayEarnings)&&(identical(other.todayTrips, todayTrips) || other.todayTrips == todayTrips)&&(identical(other.hoursOnline, hoursOnline) || other.hoursOnline == hoursOnline)&&const DeepCollectionEquality().equals(other.surgeCells, surgeCells)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isOnline,isLoadingStats,isLoadingHeatmap,todayEarnings,todayTrips,hoursOnline,const DeepCollectionEquality().hash(surgeCells),errorMessage);

@override
String toString() {
  return 'DashboardState(isOnline: $isOnline, isLoadingStats: $isLoadingStats, isLoadingHeatmap: $isLoadingHeatmap, todayEarnings: $todayEarnings, todayTrips: $todayTrips, hoursOnline: $hoursOnline, surgeCells: $surgeCells, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $DashboardStateCopyWith<$Res>  {
  factory $DashboardStateCopyWith(DashboardState value, $Res Function(DashboardState) _then) = _$DashboardStateCopyWithImpl;
@useResult
$Res call({
 bool isOnline, bool isLoadingStats, bool isLoadingHeatmap, double todayEarnings, int todayTrips, double hoursOnline, List<HeatmapCell> surgeCells, String? errorMessage
});




}
/// @nodoc
class _$DashboardStateCopyWithImpl<$Res>
    implements $DashboardStateCopyWith<$Res> {
  _$DashboardStateCopyWithImpl(this._self, this._then);

  final DashboardState _self;
  final $Res Function(DashboardState) _then;

/// Create a copy of DashboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOnline = null,Object? isLoadingStats = null,Object? isLoadingHeatmap = null,Object? todayEarnings = null,Object? todayTrips = null,Object? hoursOnline = null,Object? surgeCells = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,isLoadingStats: null == isLoadingStats ? _self.isLoadingStats : isLoadingStats // ignore: cast_nullable_to_non_nullable
as bool,isLoadingHeatmap: null == isLoadingHeatmap ? _self.isLoadingHeatmap : isLoadingHeatmap // ignore: cast_nullable_to_non_nullable
as bool,todayEarnings: null == todayEarnings ? _self.todayEarnings : todayEarnings // ignore: cast_nullable_to_non_nullable
as double,todayTrips: null == todayTrips ? _self.todayTrips : todayTrips // ignore: cast_nullable_to_non_nullable
as int,hoursOnline: null == hoursOnline ? _self.hoursOnline : hoursOnline // ignore: cast_nullable_to_non_nullable
as double,surgeCells: null == surgeCells ? _self.surgeCells : surgeCells // ignore: cast_nullable_to_non_nullable
as List<HeatmapCell>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardState].
extension DashboardStatePatterns on DashboardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardState value)  $default,){
final _that = this;
switch (_that) {
case _DashboardState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardState value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOnline,  bool isLoadingStats,  bool isLoadingHeatmap,  double todayEarnings,  int todayTrips,  double hoursOnline,  List<HeatmapCell> surgeCells,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardState() when $default != null:
return $default(_that.isOnline,_that.isLoadingStats,_that.isLoadingHeatmap,_that.todayEarnings,_that.todayTrips,_that.hoursOnline,_that.surgeCells,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOnline,  bool isLoadingStats,  bool isLoadingHeatmap,  double todayEarnings,  int todayTrips,  double hoursOnline,  List<HeatmapCell> surgeCells,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _DashboardState():
return $default(_that.isOnline,_that.isLoadingStats,_that.isLoadingHeatmap,_that.todayEarnings,_that.todayTrips,_that.hoursOnline,_that.surgeCells,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOnline,  bool isLoadingStats,  bool isLoadingHeatmap,  double todayEarnings,  int todayTrips,  double hoursOnline,  List<HeatmapCell> surgeCells,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _DashboardState() when $default != null:
return $default(_that.isOnline,_that.isLoadingStats,_that.isLoadingHeatmap,_that.todayEarnings,_that.todayTrips,_that.hoursOnline,_that.surgeCells,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _DashboardState implements DashboardState {
  const _DashboardState({this.isOnline = false, this.isLoadingStats = false, this.isLoadingHeatmap = false, this.todayEarnings = 0.0, this.todayTrips = 0, this.hoursOnline = 0.0, final  List<HeatmapCell> surgeCells = const [], this.errorMessage}): _surgeCells = surgeCells;
  

@override@JsonKey() final  bool isOnline;
@override@JsonKey() final  bool isLoadingStats;
@override@JsonKey() final  bool isLoadingHeatmap;
@override@JsonKey() final  double todayEarnings;
@override@JsonKey() final  int todayTrips;
@override@JsonKey() final  double hoursOnline;
 final  List<HeatmapCell> _surgeCells;
@override@JsonKey() List<HeatmapCell> get surgeCells {
  if (_surgeCells is EqualUnmodifiableListView) return _surgeCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_surgeCells);
}

@override final  String? errorMessage;

/// Create a copy of DashboardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardStateCopyWith<_DashboardState> get copyWith => __$DashboardStateCopyWithImpl<_DashboardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardState&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.isLoadingStats, isLoadingStats) || other.isLoadingStats == isLoadingStats)&&(identical(other.isLoadingHeatmap, isLoadingHeatmap) || other.isLoadingHeatmap == isLoadingHeatmap)&&(identical(other.todayEarnings, todayEarnings) || other.todayEarnings == todayEarnings)&&(identical(other.todayTrips, todayTrips) || other.todayTrips == todayTrips)&&(identical(other.hoursOnline, hoursOnline) || other.hoursOnline == hoursOnline)&&const DeepCollectionEquality().equals(other._surgeCells, _surgeCells)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isOnline,isLoadingStats,isLoadingHeatmap,todayEarnings,todayTrips,hoursOnline,const DeepCollectionEquality().hash(_surgeCells),errorMessage);

@override
String toString() {
  return 'DashboardState(isOnline: $isOnline, isLoadingStats: $isLoadingStats, isLoadingHeatmap: $isLoadingHeatmap, todayEarnings: $todayEarnings, todayTrips: $todayTrips, hoursOnline: $hoursOnline, surgeCells: $surgeCells, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$DashboardStateCopyWith<$Res> implements $DashboardStateCopyWith<$Res> {
  factory _$DashboardStateCopyWith(_DashboardState value, $Res Function(_DashboardState) _then) = __$DashboardStateCopyWithImpl;
@override @useResult
$Res call({
 bool isOnline, bool isLoadingStats, bool isLoadingHeatmap, double todayEarnings, int todayTrips, double hoursOnline, List<HeatmapCell> surgeCells, String? errorMessage
});




}
/// @nodoc
class __$DashboardStateCopyWithImpl<$Res>
    implements _$DashboardStateCopyWith<$Res> {
  __$DashboardStateCopyWithImpl(this._self, this._then);

  final _DashboardState _self;
  final $Res Function(_DashboardState) _then;

/// Create a copy of DashboardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOnline = null,Object? isLoadingStats = null,Object? isLoadingHeatmap = null,Object? todayEarnings = null,Object? todayTrips = null,Object? hoursOnline = null,Object? surgeCells = null,Object? errorMessage = freezed,}) {
  return _then(_DashboardState(
isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,isLoadingStats: null == isLoadingStats ? _self.isLoadingStats : isLoadingStats // ignore: cast_nullable_to_non_nullable
as bool,isLoadingHeatmap: null == isLoadingHeatmap ? _self.isLoadingHeatmap : isLoadingHeatmap // ignore: cast_nullable_to_non_nullable
as bool,todayEarnings: null == todayEarnings ? _self.todayEarnings : todayEarnings // ignore: cast_nullable_to_non_nullable
as double,todayTrips: null == todayTrips ? _self.todayTrips : todayTrips // ignore: cast_nullable_to_non_nullable
as int,hoursOnline: null == hoursOnline ? _self.hoursOnline : hoursOnline // ignore: cast_nullable_to_non_nullable
as double,surgeCells: null == surgeCells ? _self._surgeCells : surgeCells // ignore: cast_nullable_to_non_nullable
as List<HeatmapCell>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../saved_places_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedPlacesState {

 List<SavedPlace> get places; bool get isLoading; String? get errorMessage;
/// Create a copy of SavedPlacesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedPlacesStateCopyWith<SavedPlacesState> get copyWith => _$SavedPlacesStateCopyWithImpl<SavedPlacesState>(this as SavedPlacesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedPlacesState&&const DeepCollectionEquality().equals(other.places, places)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(places),isLoading,errorMessage);

@override
String toString() {
  return 'SavedPlacesState(places: $places, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SavedPlacesStateCopyWith<$Res>  {
  factory $SavedPlacesStateCopyWith(SavedPlacesState value, $Res Function(SavedPlacesState) _then) = _$SavedPlacesStateCopyWithImpl;
@useResult
$Res call({
 List<SavedPlace> places, bool isLoading, String? errorMessage
});




}
/// @nodoc
class _$SavedPlacesStateCopyWithImpl<$Res>
    implements $SavedPlacesStateCopyWith<$Res> {
  _$SavedPlacesStateCopyWithImpl(this._self, this._then);

  final SavedPlacesState _self;
  final $Res Function(SavedPlacesState) _then;

/// Create a copy of SavedPlacesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? places = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
places: null == places ? _self.places : places // ignore: cast_nullable_to_non_nullable
as List<SavedPlace>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedPlacesState].
extension SavedPlacesStatePatterns on SavedPlacesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedPlacesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedPlacesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedPlacesState value)  $default,){
final _that = this;
switch (_that) {
case _SavedPlacesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedPlacesState value)?  $default,){
final _that = this;
switch (_that) {
case _SavedPlacesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SavedPlace> places,  bool isLoading,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedPlacesState() when $default != null:
return $default(_that.places,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SavedPlace> places,  bool isLoading,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SavedPlacesState():
return $default(_that.places,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SavedPlace> places,  bool isLoading,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SavedPlacesState() when $default != null:
return $default(_that.places,_that.isLoading,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SavedPlacesState implements SavedPlacesState {
  const _SavedPlacesState({final  List<SavedPlace> places = const [], this.isLoading = true, this.errorMessage}): _places = places;
  

 final  List<SavedPlace> _places;
@override@JsonKey() List<SavedPlace> get places {
  if (_places is EqualUnmodifiableListView) return _places;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_places);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;

/// Create a copy of SavedPlacesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedPlacesStateCopyWith<_SavedPlacesState> get copyWith => __$SavedPlacesStateCopyWithImpl<_SavedPlacesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedPlacesState&&const DeepCollectionEquality().equals(other._places, _places)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_places),isLoading,errorMessage);

@override
String toString() {
  return 'SavedPlacesState(places: $places, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SavedPlacesStateCopyWith<$Res> implements $SavedPlacesStateCopyWith<$Res> {
  factory _$SavedPlacesStateCopyWith(_SavedPlacesState value, $Res Function(_SavedPlacesState) _then) = __$SavedPlacesStateCopyWithImpl;
@override @useResult
$Res call({
 List<SavedPlace> places, bool isLoading, String? errorMessage
});




}
/// @nodoc
class __$SavedPlacesStateCopyWithImpl<$Res>
    implements _$SavedPlacesStateCopyWith<$Res> {
  __$SavedPlacesStateCopyWithImpl(this._self, this._then);

  final _SavedPlacesState _self;
  final $Res Function(_SavedPlacesState) _then;

/// Create a copy of SavedPlacesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? places = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_SavedPlacesState(
places: null == places ? _self._places : places // ignore: cast_nullable_to_non_nullable
as List<SavedPlace>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

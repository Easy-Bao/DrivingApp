// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState()';
}


}

/// @nodoc
class $SettingsStateCopyWith<$Res>  {
$SettingsStateCopyWith(SettingsState _, $Res Function(SettingsState) __);
}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsInitialState value)?  initial,TResult Function( SettingsLoadingState value)?  loading,TResult Function( SettingsLoadedState value)?  loaded,TResult Function( SettingsErrorState value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsInitialState() when initial != null:
return initial(_that);case SettingsLoadingState() when loading != null:
return loading(_that);case SettingsLoadedState() when loaded != null:
return loaded(_that);case SettingsErrorState() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsInitialState value)  initial,required TResult Function( SettingsLoadingState value)  loading,required TResult Function( SettingsLoadedState value)  loaded,required TResult Function( SettingsErrorState value)  error,}){
final _that = this;
switch (_that) {
case SettingsInitialState():
return initial(_that);case SettingsLoadingState():
return loading(_that);case SettingsLoadedState():
return loaded(_that);case SettingsErrorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsInitialState value)?  initial,TResult? Function( SettingsLoadingState value)?  loading,TResult? Function( SettingsLoadedState value)?  loaded,TResult? Function( SettingsErrorState value)?  error,}){
final _that = this;
switch (_that) {
case SettingsInitialState() when initial != null:
return initial(_that);case SettingsLoadingState() when loading != null:
return loading(_that);case SettingsLoadedState() when loaded != null:
return loaded(_that);case SettingsErrorState() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( UserSettings settings)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsInitialState() when initial != null:
return initial();case SettingsLoadingState() when loading != null:
return loading();case SettingsLoadedState() when loaded != null:
return loaded(_that.settings);case SettingsErrorState() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( UserSettings settings)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SettingsInitialState():
return initial();case SettingsLoadingState():
return loading();case SettingsLoadedState():
return loaded(_that.settings);case SettingsErrorState():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( UserSettings settings)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SettingsInitialState() when initial != null:
return initial();case SettingsLoadingState() when loading != null:
return loading();case SettingsLoadedState() when loaded != null:
return loaded(_that.settings);case SettingsErrorState() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SettingsInitialState implements SettingsState {
  const SettingsInitialState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsInitialState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState.initial()';
}


}




/// @nodoc


class SettingsLoadingState implements SettingsState {
  const SettingsLoadingState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsLoadingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState.loading()';
}


}




/// @nodoc


class SettingsLoadedState implements SettingsState {
  const SettingsLoadedState(this.settings);
  

 final  UserSettings settings;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsLoadedStateCopyWith<SettingsLoadedState> get copyWith => _$SettingsLoadedStateCopyWithImpl<SettingsLoadedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsLoadedState&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode => Object.hash(runtimeType,settings);

@override
String toString() {
  return 'SettingsState.loaded(settings: $settings)';
}


}

/// @nodoc
abstract mixin class $SettingsLoadedStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsLoadedStateCopyWith(SettingsLoadedState value, $Res Function(SettingsLoadedState) _then) = _$SettingsLoadedStateCopyWithImpl;
@useResult
$Res call({
 UserSettings settings
});


$UserSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$SettingsLoadedStateCopyWithImpl<$Res>
    implements $SettingsLoadedStateCopyWith<$Res> {
  _$SettingsLoadedStateCopyWithImpl(this._self, this._then);

  final SettingsLoadedState _self;
  final $Res Function(SettingsLoadedState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(SettingsLoadedState(
null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,
  ));
}

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc


class SettingsErrorState implements SettingsState {
  const SettingsErrorState(this.message);
  

 final  String message;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsErrorStateCopyWith<SettingsErrorState> get copyWith => _$SettingsErrorStateCopyWithImpl<SettingsErrorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsErrorState&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SettingsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SettingsErrorStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsErrorStateCopyWith(SettingsErrorState value, $Res Function(SettingsErrorState) _then) = _$SettingsErrorStateCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SettingsErrorStateCopyWithImpl<$Res>
    implements $SettingsErrorStateCopyWith<$Res> {
  _$SettingsErrorStateCopyWithImpl(this._self, this._then);

  final SettingsErrorState _self;
  final $Res Function(SettingsErrorState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SettingsErrorState(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

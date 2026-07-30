// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../reset_password_confirm_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResetPasswordConfirmState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordConfirmState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ResetPasswordConfirmState()';
}


}

/// @nodoc
class $ResetPasswordConfirmStateCopyWith<$Res>  {
$ResetPasswordConfirmStateCopyWith(ResetPasswordConfirmState _, $Res Function(ResetPasswordConfirmState) __);
}


/// Adds pattern-matching-related methods to [ResetPasswordConfirmState].
extension ResetPasswordConfirmStatePatterns on ResetPasswordConfirmState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ResetPasswordConfirmInitial value)?  initial,TResult Function( ResetPasswordConfirmLoading value)?  loading,TResult Function( ResetPasswordConfirmSuccess value)?  success,TResult Function( ResetPasswordConfirmFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ResetPasswordConfirmInitial() when initial != null:
return initial(_that);case ResetPasswordConfirmLoading() when loading != null:
return loading(_that);case ResetPasswordConfirmSuccess() when success != null:
return success(_that);case ResetPasswordConfirmFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ResetPasswordConfirmInitial value)  initial,required TResult Function( ResetPasswordConfirmLoading value)  loading,required TResult Function( ResetPasswordConfirmSuccess value)  success,required TResult Function( ResetPasswordConfirmFailure value)  failure,}){
final _that = this;
switch (_that) {
case ResetPasswordConfirmInitial():
return initial(_that);case ResetPasswordConfirmLoading():
return loading(_that);case ResetPasswordConfirmSuccess():
return success(_that);case ResetPasswordConfirmFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ResetPasswordConfirmInitial value)?  initial,TResult? Function( ResetPasswordConfirmLoading value)?  loading,TResult? Function( ResetPasswordConfirmSuccess value)?  success,TResult? Function( ResetPasswordConfirmFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ResetPasswordConfirmInitial() when initial != null:
return initial(_that);case ResetPasswordConfirmLoading() when loading != null:
return loading(_that);case ResetPasswordConfirmSuccess() when success != null:
return success(_that);case ResetPasswordConfirmFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  success,TResult Function( String errorMessage)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ResetPasswordConfirmInitial() when initial != null:
return initial();case ResetPasswordConfirmLoading() when loading != null:
return loading();case ResetPasswordConfirmSuccess() when success != null:
return success();case ResetPasswordConfirmFailure() when failure != null:
return failure(_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  success,required TResult Function( String errorMessage)  failure,}) {final _that = this;
switch (_that) {
case ResetPasswordConfirmInitial():
return initial();case ResetPasswordConfirmLoading():
return loading();case ResetPasswordConfirmSuccess():
return success();case ResetPasswordConfirmFailure():
return failure(_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  success,TResult? Function( String errorMessage)?  failure,}) {final _that = this;
switch (_that) {
case ResetPasswordConfirmInitial() when initial != null:
return initial();case ResetPasswordConfirmLoading() when loading != null:
return loading();case ResetPasswordConfirmSuccess() when success != null:
return success();case ResetPasswordConfirmFailure() when failure != null:
return failure(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class ResetPasswordConfirmInitial implements ResetPasswordConfirmState {
  const ResetPasswordConfirmInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordConfirmInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ResetPasswordConfirmState.initial()';
}


}




/// @nodoc


class ResetPasswordConfirmLoading implements ResetPasswordConfirmState {
  const ResetPasswordConfirmLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordConfirmLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ResetPasswordConfirmState.loading()';
}


}




/// @nodoc


class ResetPasswordConfirmSuccess implements ResetPasswordConfirmState {
  const ResetPasswordConfirmSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordConfirmSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ResetPasswordConfirmState.success()';
}


}




/// @nodoc


class ResetPasswordConfirmFailure implements ResetPasswordConfirmState {
  const ResetPasswordConfirmFailure(this.errorMessage);
  

 final  String errorMessage;

/// Create a copy of ResetPasswordConfirmState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordConfirmFailureCopyWith<ResetPasswordConfirmFailure> get copyWith => _$ResetPasswordConfirmFailureCopyWithImpl<ResetPasswordConfirmFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordConfirmFailure&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'ResetPasswordConfirmState.failure(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordConfirmFailureCopyWith<$Res> implements $ResetPasswordConfirmStateCopyWith<$Res> {
  factory $ResetPasswordConfirmFailureCopyWith(ResetPasswordConfirmFailure value, $Res Function(ResetPasswordConfirmFailure) _then) = _$ResetPasswordConfirmFailureCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$ResetPasswordConfirmFailureCopyWithImpl<$Res>
    implements $ResetPasswordConfirmFailureCopyWith<$Res> {
  _$ResetPasswordConfirmFailureCopyWithImpl(this._self, this._then);

  final ResetPasswordConfirmFailure _self;
  final $Res Function(ResetPasswordConfirmFailure) _then;

/// Create a copy of ResetPasswordConfirmState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(ResetPasswordConfirmFailure(
null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

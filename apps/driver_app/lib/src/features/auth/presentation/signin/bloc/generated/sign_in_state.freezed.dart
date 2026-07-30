// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../sign_in_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignInState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignInState()';
}


}

/// @nodoc
class $SignInStateCopyWith<$Res>  {
$SignInStateCopyWith(SignInState _, $Res Function(SignInState) __);
}


/// Adds pattern-matching-related methods to [SignInState].
extension SignInStatePatterns on SignInState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SignInInitial value)?  initial,TResult Function( SignInLoading value)?  loading,TResult Function( SignInSuccess value)?  success,TResult Function( SignInFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SignInInitial() when initial != null:
return initial(_that);case SignInLoading() when loading != null:
return loading(_that);case SignInSuccess() when success != null:
return success(_that);case SignInFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SignInInitial value)  initial,required TResult Function( SignInLoading value)  loading,required TResult Function( SignInSuccess value)  success,required TResult Function( SignInFailure value)  failure,}){
final _that = this;
switch (_that) {
case SignInInitial():
return initial(_that);case SignInLoading():
return loading(_that);case SignInSuccess():
return success(_that);case SignInFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SignInInitial value)?  initial,TResult? Function( SignInLoading value)?  loading,TResult? Function( SignInSuccess value)?  success,TResult? Function( SignInFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SignInInitial() when initial != null:
return initial(_that);case SignInLoading() when loading != null:
return loading(_that);case SignInSuccess() when success != null:
return success(_that);case SignInFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( AuthCredentials credentials)?  success,TResult Function( String errorMessage)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SignInInitial() when initial != null:
return initial();case SignInLoading() when loading != null:
return loading();case SignInSuccess() when success != null:
return success(_that.credentials);case SignInFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( AuthCredentials credentials)  success,required TResult Function( String errorMessage)  failure,}) {final _that = this;
switch (_that) {
case SignInInitial():
return initial();case SignInLoading():
return loading();case SignInSuccess():
return success(_that.credentials);case SignInFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( AuthCredentials credentials)?  success,TResult? Function( String errorMessage)?  failure,}) {final _that = this;
switch (_that) {
case SignInInitial() when initial != null:
return initial();case SignInLoading() when loading != null:
return loading();case SignInSuccess() when success != null:
return success(_that.credentials);case SignInFailure() when failure != null:
return failure(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class SignInInitial implements SignInState {
  const SignInInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignInState.initial()';
}


}




/// @nodoc


class SignInLoading implements SignInState {
  const SignInLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignInState.loading()';
}


}




/// @nodoc


class SignInSuccess implements SignInState {
  const SignInSuccess(this.credentials);
  

 final  AuthCredentials credentials;

/// Create a copy of SignInState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignInSuccessCopyWith<SignInSuccess> get copyWith => _$SignInSuccessCopyWithImpl<SignInSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInSuccess&&(identical(other.credentials, credentials) || other.credentials == credentials));
}


@override
int get hashCode => Object.hash(runtimeType,credentials);

@override
String toString() {
  return 'SignInState.success(credentials: $credentials)';
}


}

/// @nodoc
abstract mixin class $SignInSuccessCopyWith<$Res> implements $SignInStateCopyWith<$Res> {
  factory $SignInSuccessCopyWith(SignInSuccess value, $Res Function(SignInSuccess) _then) = _$SignInSuccessCopyWithImpl;
@useResult
$Res call({
 AuthCredentials credentials
});


$AuthCredentialsCopyWith<$Res> get credentials;

}
/// @nodoc
class _$SignInSuccessCopyWithImpl<$Res>
    implements $SignInSuccessCopyWith<$Res> {
  _$SignInSuccessCopyWithImpl(this._self, this._then);

  final SignInSuccess _self;
  final $Res Function(SignInSuccess) _then;

/// Create a copy of SignInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? credentials = null,}) {
  return _then(SignInSuccess(
null == credentials ? _self.credentials : credentials // ignore: cast_nullable_to_non_nullable
as AuthCredentials,
  ));
}

/// Create a copy of SignInState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthCredentialsCopyWith<$Res> get credentials {
  
  return $AuthCredentialsCopyWith<$Res>(_self.credentials, (value) {
    return _then(_self.copyWith(credentials: value));
  });
}
}

/// @nodoc


class SignInFailure implements SignInState {
  const SignInFailure(this.errorMessage);
  

 final  String errorMessage;

/// Create a copy of SignInState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignInFailureCopyWith<SignInFailure> get copyWith => _$SignInFailureCopyWithImpl<SignInFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInFailure&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'SignInState.failure(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SignInFailureCopyWith<$Res> implements $SignInStateCopyWith<$Res> {
  factory $SignInFailureCopyWith(SignInFailure value, $Res Function(SignInFailure) _then) = _$SignInFailureCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$SignInFailureCopyWithImpl<$Res>
    implements $SignInFailureCopyWith<$Res> {
  _$SignInFailureCopyWithImpl(this._self, this._then);

  final SignInFailure _self;
  final $Res Function(SignInFailure) _then;

/// Create a copy of SignInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(SignInFailure(
null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

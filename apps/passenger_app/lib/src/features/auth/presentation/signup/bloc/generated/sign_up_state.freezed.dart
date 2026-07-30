// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../sign_up_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignUpState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpState()';
}


}

/// @nodoc
class $SignUpStateCopyWith<$Res>  {
$SignUpStateCopyWith(SignUpState _, $Res Function(SignUpState) __);
}


/// Adds pattern-matching-related methods to [SignUpState].
extension SignUpStatePatterns on SignUpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SignUpInitial value)?  initial,TResult Function( SignUpLoading value)?  loading,TResult Function( SignUpNeedsVerification value)?  needsVerification,TResult Function( SignUpSuccess value)?  success,TResult Function( SignUpFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SignUpInitial() when initial != null:
return initial(_that);case SignUpLoading() when loading != null:
return loading(_that);case SignUpNeedsVerification() when needsVerification != null:
return needsVerification(_that);case SignUpSuccess() when success != null:
return success(_that);case SignUpFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SignUpInitial value)  initial,required TResult Function( SignUpLoading value)  loading,required TResult Function( SignUpNeedsVerification value)  needsVerification,required TResult Function( SignUpSuccess value)  success,required TResult Function( SignUpFailure value)  failure,}){
final _that = this;
switch (_that) {
case SignUpInitial():
return initial(_that);case SignUpLoading():
return loading(_that);case SignUpNeedsVerification():
return needsVerification(_that);case SignUpSuccess():
return success(_that);case SignUpFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SignUpInitial value)?  initial,TResult? Function( SignUpLoading value)?  loading,TResult? Function( SignUpNeedsVerification value)?  needsVerification,TResult? Function( SignUpSuccess value)?  success,TResult? Function( SignUpFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SignUpInitial() when initial != null:
return initial(_that);case SignUpLoading() when loading != null:
return loading(_that);case SignUpNeedsVerification() when needsVerification != null:
return needsVerification(_that);case SignUpSuccess() when success != null:
return success(_that);case SignUpFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String email)?  needsVerification,TResult Function( AuthCredentials credentials)?  success,TResult Function( String errorMessage)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SignUpInitial() when initial != null:
return initial();case SignUpLoading() when loading != null:
return loading();case SignUpNeedsVerification() when needsVerification != null:
return needsVerification(_that.email);case SignUpSuccess() when success != null:
return success(_that.credentials);case SignUpFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String email)  needsVerification,required TResult Function( AuthCredentials credentials)  success,required TResult Function( String errorMessage)  failure,}) {final _that = this;
switch (_that) {
case SignUpInitial():
return initial();case SignUpLoading():
return loading();case SignUpNeedsVerification():
return needsVerification(_that.email);case SignUpSuccess():
return success(_that.credentials);case SignUpFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String email)?  needsVerification,TResult? Function( AuthCredentials credentials)?  success,TResult? Function( String errorMessage)?  failure,}) {final _that = this;
switch (_that) {
case SignUpInitial() when initial != null:
return initial();case SignUpLoading() when loading != null:
return loading();case SignUpNeedsVerification() when needsVerification != null:
return needsVerification(_that.email);case SignUpSuccess() when success != null:
return success(_that.credentials);case SignUpFailure() when failure != null:
return failure(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class SignUpInitial implements SignUpState {
  const SignUpInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpState.initial()';
}


}




/// @nodoc


class SignUpLoading implements SignUpState {
  const SignUpLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpState.loading()';
}


}




/// @nodoc


class SignUpNeedsVerification implements SignUpState {
  const SignUpNeedsVerification(this.email);
  

 final  String email;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpNeedsVerificationCopyWith<SignUpNeedsVerification> get copyWith => _$SignUpNeedsVerificationCopyWithImpl<SignUpNeedsVerification>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpNeedsVerification&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'SignUpState.needsVerification(email: $email)';
}


}

/// @nodoc
abstract mixin class $SignUpNeedsVerificationCopyWith<$Res> implements $SignUpStateCopyWith<$Res> {
  factory $SignUpNeedsVerificationCopyWith(SignUpNeedsVerification value, $Res Function(SignUpNeedsVerification) _then) = _$SignUpNeedsVerificationCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$SignUpNeedsVerificationCopyWithImpl<$Res>
    implements $SignUpNeedsVerificationCopyWith<$Res> {
  _$SignUpNeedsVerificationCopyWithImpl(this._self, this._then);

  final SignUpNeedsVerification _self;
  final $Res Function(SignUpNeedsVerification) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(SignUpNeedsVerification(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SignUpSuccess implements SignUpState {
  const SignUpSuccess(this.credentials);
  

 final  AuthCredentials credentials;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpSuccessCopyWith<SignUpSuccess> get copyWith => _$SignUpSuccessCopyWithImpl<SignUpSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpSuccess&&(identical(other.credentials, credentials) || other.credentials == credentials));
}


@override
int get hashCode => Object.hash(runtimeType,credentials);

@override
String toString() {
  return 'SignUpState.success(credentials: $credentials)';
}


}

/// @nodoc
abstract mixin class $SignUpSuccessCopyWith<$Res> implements $SignUpStateCopyWith<$Res> {
  factory $SignUpSuccessCopyWith(SignUpSuccess value, $Res Function(SignUpSuccess) _then) = _$SignUpSuccessCopyWithImpl;
@useResult
$Res call({
 AuthCredentials credentials
});


$AuthCredentialsCopyWith<$Res> get credentials;

}
/// @nodoc
class _$SignUpSuccessCopyWithImpl<$Res>
    implements $SignUpSuccessCopyWith<$Res> {
  _$SignUpSuccessCopyWithImpl(this._self, this._then);

  final SignUpSuccess _self;
  final $Res Function(SignUpSuccess) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? credentials = null,}) {
  return _then(SignUpSuccess(
null == credentials ? _self.credentials : credentials // ignore: cast_nullable_to_non_nullable
as AuthCredentials,
  ));
}

/// Create a copy of SignUpState
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


class SignUpFailure implements SignUpState {
  const SignUpFailure(this.errorMessage);
  

 final  String errorMessage;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpFailureCopyWith<SignUpFailure> get copyWith => _$SignUpFailureCopyWithImpl<SignUpFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpFailure&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'SignUpState.failure(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SignUpFailureCopyWith<$Res> implements $SignUpStateCopyWith<$Res> {
  factory $SignUpFailureCopyWith(SignUpFailure value, $Res Function(SignUpFailure) _then) = _$SignUpFailureCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$SignUpFailureCopyWithImpl<$Res>
    implements $SignUpFailureCopyWith<$Res> {
  _$SignUpFailureCopyWithImpl(this._self, this._then);

  final SignUpFailure _self;
  final $Res Function(SignUpFailure) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(SignUpFailure(
null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

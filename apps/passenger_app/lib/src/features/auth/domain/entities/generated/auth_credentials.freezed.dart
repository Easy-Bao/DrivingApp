// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../auth_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthCredentials {

 String get passengerId; String get passengerName; String get passengerEmail; String get passengerPhone; String get token; bool get needsVerification;
/// Create a copy of AuthCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthCredentialsCopyWith<AuthCredentials> get copyWith => _$AuthCredentialsCopyWithImpl<AuthCredentials>(this as AuthCredentials, _$identity);

  /// Serializes this AuthCredentials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthCredentials&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.passengerEmail, passengerEmail) || other.passengerEmail == passengerEmail)&&(identical(other.passengerPhone, passengerPhone) || other.passengerPhone == passengerPhone)&&(identical(other.token, token) || other.token == token)&&(identical(other.needsVerification, needsVerification) || other.needsVerification == needsVerification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passengerId,passengerName,passengerEmail,passengerPhone,token,needsVerification);

@override
String toString() {
  return 'AuthCredentials(passengerId: $passengerId, passengerName: $passengerName, passengerEmail: $passengerEmail, passengerPhone: $passengerPhone, token: $token, needsVerification: $needsVerification)';
}


}

/// @nodoc
abstract mixin class $AuthCredentialsCopyWith<$Res>  {
  factory $AuthCredentialsCopyWith(AuthCredentials value, $Res Function(AuthCredentials) _then) = _$AuthCredentialsCopyWithImpl;
@useResult
$Res call({
 String passengerId, String passengerName, String passengerEmail, String passengerPhone, String token, bool needsVerification
});




}
/// @nodoc
class _$AuthCredentialsCopyWithImpl<$Res>
    implements $AuthCredentialsCopyWith<$Res> {
  _$AuthCredentialsCopyWithImpl(this._self, this._then);

  final AuthCredentials _self;
  final $Res Function(AuthCredentials) _then;

/// Create a copy of AuthCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? passengerId = null,Object? passengerName = null,Object? passengerEmail = null,Object? passengerPhone = null,Object? token = null,Object? needsVerification = null,}) {
  return _then(_self.copyWith(
passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,passengerEmail: null == passengerEmail ? _self.passengerEmail : passengerEmail // ignore: cast_nullable_to_non_nullable
as String,passengerPhone: null == passengerPhone ? _self.passengerPhone : passengerPhone // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,needsVerification: null == needsVerification ? _self.needsVerification : needsVerification // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthCredentials].
extension AuthCredentialsPatterns on AuthCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthCredentials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthCredentials value)  $default,){
final _that = this;
switch (_that) {
case _AuthCredentials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _AuthCredentials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String passengerId,  String passengerName,  String passengerEmail,  String passengerPhone,  String token,  bool needsVerification)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthCredentials() when $default != null:
return $default(_that.passengerId,_that.passengerName,_that.passengerEmail,_that.passengerPhone,_that.token,_that.needsVerification);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String passengerId,  String passengerName,  String passengerEmail,  String passengerPhone,  String token,  bool needsVerification)  $default,) {final _that = this;
switch (_that) {
case _AuthCredentials():
return $default(_that.passengerId,_that.passengerName,_that.passengerEmail,_that.passengerPhone,_that.token,_that.needsVerification);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String passengerId,  String passengerName,  String passengerEmail,  String passengerPhone,  String token,  bool needsVerification)?  $default,) {final _that = this;
switch (_that) {
case _AuthCredentials() when $default != null:
return $default(_that.passengerId,_that.passengerName,_that.passengerEmail,_that.passengerPhone,_that.token,_that.needsVerification);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthCredentials implements AuthCredentials {
  const _AuthCredentials({required this.passengerId, required this.passengerName, required this.passengerEmail, required this.passengerPhone, required this.token, this.needsVerification = false});
  factory _AuthCredentials.fromJson(Map<String, dynamic> json) => _$AuthCredentialsFromJson(json);

@override final  String passengerId;
@override final  String passengerName;
@override final  String passengerEmail;
@override final  String passengerPhone;
@override final  String token;
@override@JsonKey() final  bool needsVerification;

/// Create a copy of AuthCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthCredentialsCopyWith<_AuthCredentials> get copyWith => __$AuthCredentialsCopyWithImpl<_AuthCredentials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthCredentialsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthCredentials&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.passengerEmail, passengerEmail) || other.passengerEmail == passengerEmail)&&(identical(other.passengerPhone, passengerPhone) || other.passengerPhone == passengerPhone)&&(identical(other.token, token) || other.token == token)&&(identical(other.needsVerification, needsVerification) || other.needsVerification == needsVerification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passengerId,passengerName,passengerEmail,passengerPhone,token,needsVerification);

@override
String toString() {
  return 'AuthCredentials(passengerId: $passengerId, passengerName: $passengerName, passengerEmail: $passengerEmail, passengerPhone: $passengerPhone, token: $token, needsVerification: $needsVerification)';
}


}

/// @nodoc
abstract mixin class _$AuthCredentialsCopyWith<$Res> implements $AuthCredentialsCopyWith<$Res> {
  factory _$AuthCredentialsCopyWith(_AuthCredentials value, $Res Function(_AuthCredentials) _then) = __$AuthCredentialsCopyWithImpl;
@override @useResult
$Res call({
 String passengerId, String passengerName, String passengerEmail, String passengerPhone, String token, bool needsVerification
});




}
/// @nodoc
class __$AuthCredentialsCopyWithImpl<$Res>
    implements _$AuthCredentialsCopyWith<$Res> {
  __$AuthCredentialsCopyWithImpl(this._self, this._then);

  final _AuthCredentials _self;
  final $Res Function(_AuthCredentials) _then;

/// Create a copy of AuthCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? passengerId = null,Object? passengerName = null,Object? passengerEmail = null,Object? passengerPhone = null,Object? token = null,Object? needsVerification = null,}) {
  return _then(_AuthCredentials(
passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,passengerEmail: null == passengerEmail ? _self.passengerEmail : passengerEmail // ignore: cast_nullable_to_non_nullable
as String,passengerPhone: null == passengerPhone ? _self.passengerPhone : passengerPhone // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,needsVerification: null == needsVerification ? _self.needsVerification : needsVerification // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

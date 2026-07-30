// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../reset_password_confirm_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResetPasswordConfirmEvent {

 String get email; String get code; String get newPassword;
/// Create a copy of ResetPasswordConfirmEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordConfirmEventCopyWith<ResetPasswordConfirmEvent> get copyWith => _$ResetPasswordConfirmEventCopyWithImpl<ResetPasswordConfirmEvent>(this as ResetPasswordConfirmEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordConfirmEvent&&(identical(other.email, email) || other.email == email)&&(identical(other.code, code) || other.code == code)&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword));
}


@override
int get hashCode => Object.hash(runtimeType,email,code,newPassword);

@override
String toString() {
  return 'ResetPasswordConfirmEvent(email: $email, code: $code, newPassword: $newPassword)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordConfirmEventCopyWith<$Res>  {
  factory $ResetPasswordConfirmEventCopyWith(ResetPasswordConfirmEvent value, $Res Function(ResetPasswordConfirmEvent) _then) = _$ResetPasswordConfirmEventCopyWithImpl;
@useResult
$Res call({
 String email, String code, String newPassword
});




}
/// @nodoc
class _$ResetPasswordConfirmEventCopyWithImpl<$Res>
    implements $ResetPasswordConfirmEventCopyWith<$Res> {
  _$ResetPasswordConfirmEventCopyWithImpl(this._self, this._then);

  final ResetPasswordConfirmEvent _self;
  final $Res Function(ResetPasswordConfirmEvent) _then;

/// Create a copy of ResetPasswordConfirmEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? code = null,Object? newPassword = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ResetPasswordConfirmEvent].
extension ResetPasswordConfirmEventPatterns on ResetPasswordConfirmEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ResetPasswordConfirmSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ResetPasswordConfirmSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ResetPasswordConfirmSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case ResetPasswordConfirmSubmitted():
return submitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ResetPasswordConfirmSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case ResetPasswordConfirmSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String email,  String code,  String newPassword)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ResetPasswordConfirmSubmitted() when submitted != null:
return submitted(_that.email,_that.code,_that.newPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String email,  String code,  String newPassword)  submitted,}) {final _that = this;
switch (_that) {
case ResetPasswordConfirmSubmitted():
return submitted(_that.email,_that.code,_that.newPassword);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String email,  String code,  String newPassword)?  submitted,}) {final _that = this;
switch (_that) {
case ResetPasswordConfirmSubmitted() when submitted != null:
return submitted(_that.email,_that.code,_that.newPassword);case _:
  return null;

}
}

}

/// @nodoc


class ResetPasswordConfirmSubmitted implements ResetPasswordConfirmEvent {
  const ResetPasswordConfirmSubmitted({required this.email, required this.code, required this.newPassword});
  

@override final  String email;
@override final  String code;
@override final  String newPassword;

/// Create a copy of ResetPasswordConfirmEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordConfirmSubmittedCopyWith<ResetPasswordConfirmSubmitted> get copyWith => _$ResetPasswordConfirmSubmittedCopyWithImpl<ResetPasswordConfirmSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordConfirmSubmitted&&(identical(other.email, email) || other.email == email)&&(identical(other.code, code) || other.code == code)&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword));
}


@override
int get hashCode => Object.hash(runtimeType,email,code,newPassword);

@override
String toString() {
  return 'ResetPasswordConfirmEvent.submitted(email: $email, code: $code, newPassword: $newPassword)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordConfirmSubmittedCopyWith<$Res> implements $ResetPasswordConfirmEventCopyWith<$Res> {
  factory $ResetPasswordConfirmSubmittedCopyWith(ResetPasswordConfirmSubmitted value, $Res Function(ResetPasswordConfirmSubmitted) _then) = _$ResetPasswordConfirmSubmittedCopyWithImpl;
@override @useResult
$Res call({
 String email, String code, String newPassword
});




}
/// @nodoc
class _$ResetPasswordConfirmSubmittedCopyWithImpl<$Res>
    implements $ResetPasswordConfirmSubmittedCopyWith<$Res> {
  _$ResetPasswordConfirmSubmittedCopyWithImpl(this._self, this._then);

  final ResetPasswordConfirmSubmitted _self;
  final $Res Function(ResetPasswordConfirmSubmitted) _then;

/// Create a copy of ResetPasswordConfirmEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? code = null,Object? newPassword = null,}) {
  return _then(ResetPasswordConfirmSubmitted(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

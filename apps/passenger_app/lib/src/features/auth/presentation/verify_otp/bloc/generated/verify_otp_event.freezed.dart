// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../verify_otp_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VerifyOtpEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyOtpEvent()';
}


}

/// @nodoc
class $VerifyOtpEventCopyWith<$Res>  {
$VerifyOtpEventCopyWith(VerifyOtpEvent _, $Res Function(VerifyOtpEvent) __);
}


/// Adds pattern-matching-related methods to [VerifyOtpEvent].
extension VerifyOtpEventPatterns on VerifyOtpEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VerifyOtpTimerStarted value)?  timerStarted,TResult Function( VerifyOtpTimerTicked value)?  timerTicked,TResult Function( VerifyOtpSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VerifyOtpTimerStarted() when timerStarted != null:
return timerStarted(_that);case VerifyOtpTimerTicked() when timerTicked != null:
return timerTicked(_that);case VerifyOtpSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VerifyOtpTimerStarted value)  timerStarted,required TResult Function( VerifyOtpTimerTicked value)  timerTicked,required TResult Function( VerifyOtpSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case VerifyOtpTimerStarted():
return timerStarted(_that);case VerifyOtpTimerTicked():
return timerTicked(_that);case VerifyOtpSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VerifyOtpTimerStarted value)?  timerStarted,TResult? Function( VerifyOtpTimerTicked value)?  timerTicked,TResult? Function( VerifyOtpSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case VerifyOtpTimerStarted() when timerStarted != null:
return timerStarted(_that);case VerifyOtpTimerTicked() when timerTicked != null:
return timerTicked(_that);case VerifyOtpSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  timerStarted,TResult Function( int secondsRemaining)?  timerTicked,TResult Function( String email,  String code,  String password)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VerifyOtpTimerStarted() when timerStarted != null:
return timerStarted();case VerifyOtpTimerTicked() when timerTicked != null:
return timerTicked(_that.secondsRemaining);case VerifyOtpSubmitted() when submitted != null:
return submitted(_that.email,_that.code,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  timerStarted,required TResult Function( int secondsRemaining)  timerTicked,required TResult Function( String email,  String code,  String password)  submitted,}) {final _that = this;
switch (_that) {
case VerifyOtpTimerStarted():
return timerStarted();case VerifyOtpTimerTicked():
return timerTicked(_that.secondsRemaining);case VerifyOtpSubmitted():
return submitted(_that.email,_that.code,_that.password);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  timerStarted,TResult? Function( int secondsRemaining)?  timerTicked,TResult? Function( String email,  String code,  String password)?  submitted,}) {final _that = this;
switch (_that) {
case VerifyOtpTimerStarted() when timerStarted != null:
return timerStarted();case VerifyOtpTimerTicked() when timerTicked != null:
return timerTicked(_that.secondsRemaining);case VerifyOtpSubmitted() when submitted != null:
return submitted(_that.email,_that.code,_that.password);case _:
  return null;

}
}

}

/// @nodoc


class VerifyOtpTimerStarted implements VerifyOtpEvent {
  const VerifyOtpTimerStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpTimerStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyOtpEvent.timerStarted()';
}


}




/// @nodoc


class VerifyOtpTimerTicked implements VerifyOtpEvent {
  const VerifyOtpTimerTicked({required this.secondsRemaining});
  

 final  int secondsRemaining;

/// Create a copy of VerifyOtpEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpTimerTickedCopyWith<VerifyOtpTimerTicked> get copyWith => _$VerifyOtpTimerTickedCopyWithImpl<VerifyOtpTimerTicked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpTimerTicked&&(identical(other.secondsRemaining, secondsRemaining) || other.secondsRemaining == secondsRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,secondsRemaining);

@override
String toString() {
  return 'VerifyOtpEvent.timerTicked(secondsRemaining: $secondsRemaining)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpTimerTickedCopyWith<$Res> implements $VerifyOtpEventCopyWith<$Res> {
  factory $VerifyOtpTimerTickedCopyWith(VerifyOtpTimerTicked value, $Res Function(VerifyOtpTimerTicked) _then) = _$VerifyOtpTimerTickedCopyWithImpl;
@useResult
$Res call({
 int secondsRemaining
});




}
/// @nodoc
class _$VerifyOtpTimerTickedCopyWithImpl<$Res>
    implements $VerifyOtpTimerTickedCopyWith<$Res> {
  _$VerifyOtpTimerTickedCopyWithImpl(this._self, this._then);

  final VerifyOtpTimerTicked _self;
  final $Res Function(VerifyOtpTimerTicked) _then;

/// Create a copy of VerifyOtpEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? secondsRemaining = null,}) {
  return _then(VerifyOtpTimerTicked(
secondsRemaining: null == secondsRemaining ? _self.secondsRemaining : secondsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class VerifyOtpSubmitted implements VerifyOtpEvent {
  const VerifyOtpSubmitted({required this.email, required this.code, this.password = ''});
  

 final  String email;
 final  String code;
@JsonKey() final  String password;

/// Create a copy of VerifyOtpEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpSubmittedCopyWith<VerifyOtpSubmitted> get copyWith => _$VerifyOtpSubmittedCopyWithImpl<VerifyOtpSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpSubmitted&&(identical(other.email, email) || other.email == email)&&(identical(other.code, code) || other.code == code)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,email,code,password);

@override
String toString() {
  return 'VerifyOtpEvent.submitted(email: $email, code: $code, password: $password)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpSubmittedCopyWith<$Res> implements $VerifyOtpEventCopyWith<$Res> {
  factory $VerifyOtpSubmittedCopyWith(VerifyOtpSubmitted value, $Res Function(VerifyOtpSubmitted) _then) = _$VerifyOtpSubmittedCopyWithImpl;
@useResult
$Res call({
 String email, String code, String password
});




}
/// @nodoc
class _$VerifyOtpSubmittedCopyWithImpl<$Res>
    implements $VerifyOtpSubmittedCopyWith<$Res> {
  _$VerifyOtpSubmittedCopyWithImpl(this._self, this._then);

  final VerifyOtpSubmitted _self;
  final $Res Function(VerifyOtpSubmitted) _then;

/// Create a copy of VerifyOtpEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? code = null,Object? password = null,}) {
  return _then(VerifyOtpSubmitted(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

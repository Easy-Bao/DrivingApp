// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../verify_otp_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VerifyOtpState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyOtpState()';
}


}

/// @nodoc
class $VerifyOtpStateCopyWith<$Res>  {
$VerifyOtpStateCopyWith(VerifyOtpState _, $Res Function(VerifyOtpState) __);
}


/// Adds pattern-matching-related methods to [VerifyOtpState].
extension VerifyOtpStatePatterns on VerifyOtpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VerifyOtpInitial value)?  initial,TResult Function( VerifyOtpTimerTicking value)?  timerTicking,TResult Function( VerifyOtpTimerExpired value)?  timerExpired,TResult Function( VerifyOtpLoading value)?  loading,TResult Function( VerifyOtpSuccess value)?  success,TResult Function( VerifyOtpFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VerifyOtpInitial() when initial != null:
return initial(_that);case VerifyOtpTimerTicking() when timerTicking != null:
return timerTicking(_that);case VerifyOtpTimerExpired() when timerExpired != null:
return timerExpired(_that);case VerifyOtpLoading() when loading != null:
return loading(_that);case VerifyOtpSuccess() when success != null:
return success(_that);case VerifyOtpFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VerifyOtpInitial value)  initial,required TResult Function( VerifyOtpTimerTicking value)  timerTicking,required TResult Function( VerifyOtpTimerExpired value)  timerExpired,required TResult Function( VerifyOtpLoading value)  loading,required TResult Function( VerifyOtpSuccess value)  success,required TResult Function( VerifyOtpFailure value)  failure,}){
final _that = this;
switch (_that) {
case VerifyOtpInitial():
return initial(_that);case VerifyOtpTimerTicking():
return timerTicking(_that);case VerifyOtpTimerExpired():
return timerExpired(_that);case VerifyOtpLoading():
return loading(_that);case VerifyOtpSuccess():
return success(_that);case VerifyOtpFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VerifyOtpInitial value)?  initial,TResult? Function( VerifyOtpTimerTicking value)?  timerTicking,TResult? Function( VerifyOtpTimerExpired value)?  timerExpired,TResult? Function( VerifyOtpLoading value)?  loading,TResult? Function( VerifyOtpSuccess value)?  success,TResult? Function( VerifyOtpFailure value)?  failure,}){
final _that = this;
switch (_that) {
case VerifyOtpInitial() when initial != null:
return initial(_that);case VerifyOtpTimerTicking() when timerTicking != null:
return timerTicking(_that);case VerifyOtpTimerExpired() when timerExpired != null:
return timerExpired(_that);case VerifyOtpLoading() when loading != null:
return loading(_that);case VerifyOtpSuccess() when success != null:
return success(_that);case VerifyOtpFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( int secondsRemaining)?  timerTicking,TResult Function()?  timerExpired,TResult Function()?  loading,TResult Function()?  success,TResult Function( String errorMessage)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VerifyOtpInitial() when initial != null:
return initial();case VerifyOtpTimerTicking() when timerTicking != null:
return timerTicking(_that.secondsRemaining);case VerifyOtpTimerExpired() when timerExpired != null:
return timerExpired();case VerifyOtpLoading() when loading != null:
return loading();case VerifyOtpSuccess() when success != null:
return success();case VerifyOtpFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( int secondsRemaining)  timerTicking,required TResult Function()  timerExpired,required TResult Function()  loading,required TResult Function()  success,required TResult Function( String errorMessage)  failure,}) {final _that = this;
switch (_that) {
case VerifyOtpInitial():
return initial();case VerifyOtpTimerTicking():
return timerTicking(_that.secondsRemaining);case VerifyOtpTimerExpired():
return timerExpired();case VerifyOtpLoading():
return loading();case VerifyOtpSuccess():
return success();case VerifyOtpFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( int secondsRemaining)?  timerTicking,TResult? Function()?  timerExpired,TResult? Function()?  loading,TResult? Function()?  success,TResult? Function( String errorMessage)?  failure,}) {final _that = this;
switch (_that) {
case VerifyOtpInitial() when initial != null:
return initial();case VerifyOtpTimerTicking() when timerTicking != null:
return timerTicking(_that.secondsRemaining);case VerifyOtpTimerExpired() when timerExpired != null:
return timerExpired();case VerifyOtpLoading() when loading != null:
return loading();case VerifyOtpSuccess() when success != null:
return success();case VerifyOtpFailure() when failure != null:
return failure(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class VerifyOtpInitial implements VerifyOtpState {
  const VerifyOtpInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyOtpState.initial()';
}


}




/// @nodoc


class VerifyOtpTimerTicking implements VerifyOtpState {
  const VerifyOtpTimerTicking(this.secondsRemaining);
  

 final  int secondsRemaining;

/// Create a copy of VerifyOtpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpTimerTickingCopyWith<VerifyOtpTimerTicking> get copyWith => _$VerifyOtpTimerTickingCopyWithImpl<VerifyOtpTimerTicking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpTimerTicking&&(identical(other.secondsRemaining, secondsRemaining) || other.secondsRemaining == secondsRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,secondsRemaining);

@override
String toString() {
  return 'VerifyOtpState.timerTicking(secondsRemaining: $secondsRemaining)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpTimerTickingCopyWith<$Res> implements $VerifyOtpStateCopyWith<$Res> {
  factory $VerifyOtpTimerTickingCopyWith(VerifyOtpTimerTicking value, $Res Function(VerifyOtpTimerTicking) _then) = _$VerifyOtpTimerTickingCopyWithImpl;
@useResult
$Res call({
 int secondsRemaining
});




}
/// @nodoc
class _$VerifyOtpTimerTickingCopyWithImpl<$Res>
    implements $VerifyOtpTimerTickingCopyWith<$Res> {
  _$VerifyOtpTimerTickingCopyWithImpl(this._self, this._then);

  final VerifyOtpTimerTicking _self;
  final $Res Function(VerifyOtpTimerTicking) _then;

/// Create a copy of VerifyOtpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? secondsRemaining = null,}) {
  return _then(VerifyOtpTimerTicking(
null == secondsRemaining ? _self.secondsRemaining : secondsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class VerifyOtpTimerExpired implements VerifyOtpState {
  const VerifyOtpTimerExpired();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpTimerExpired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyOtpState.timerExpired()';
}


}




/// @nodoc


class VerifyOtpLoading implements VerifyOtpState {
  const VerifyOtpLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyOtpState.loading()';
}


}




/// @nodoc


class VerifyOtpSuccess implements VerifyOtpState {
  const VerifyOtpSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyOtpState.success()';
}


}




/// @nodoc


class VerifyOtpFailure implements VerifyOtpState {
  const VerifyOtpFailure(this.errorMessage);
  

 final  String errorMessage;

/// Create a copy of VerifyOtpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpFailureCopyWith<VerifyOtpFailure> get copyWith => _$VerifyOtpFailureCopyWithImpl<VerifyOtpFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpFailure&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'VerifyOtpState.failure(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpFailureCopyWith<$Res> implements $VerifyOtpStateCopyWith<$Res> {
  factory $VerifyOtpFailureCopyWith(VerifyOtpFailure value, $Res Function(VerifyOtpFailure) _then) = _$VerifyOtpFailureCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$VerifyOtpFailureCopyWithImpl<$Res>
    implements $VerifyOtpFailureCopyWith<$Res> {
  _$VerifyOtpFailureCopyWithImpl(this._self, this._then);

  final VerifyOtpFailure _self;
  final $Res Function(VerifyOtpFailure) _then;

/// Create a copy of VerifyOtpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(VerifyOtpFailure(
null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

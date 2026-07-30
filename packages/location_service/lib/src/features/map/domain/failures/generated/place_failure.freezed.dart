// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../place_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaceFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceFailure()';
}


}

/// @nodoc
class $PlaceFailureCopyWith<$Res>  {
$PlaceFailureCopyWith(PlaceFailure _, $Res Function(PlaceFailure) __);
}


/// Adds pattern-matching-related methods to [PlaceFailure].
extension PlaceFailurePatterns on PlaceFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaceNetworkError value)?  networkError,TResult Function( PlaceServerError value)?  serverError,TResult Function( PlaceParseError value)?  parseError,TResult Function( PlaceNotFound value)?  notFound,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaceNetworkError() when networkError != null:
return networkError(_that);case PlaceServerError() when serverError != null:
return serverError(_that);case PlaceParseError() when parseError != null:
return parseError(_that);case PlaceNotFound() when notFound != null:
return notFound(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaceNetworkError value)  networkError,required TResult Function( PlaceServerError value)  serverError,required TResult Function( PlaceParseError value)  parseError,required TResult Function( PlaceNotFound value)  notFound,}){
final _that = this;
switch (_that) {
case PlaceNetworkError():
return networkError(_that);case PlaceServerError():
return serverError(_that);case PlaceParseError():
return parseError(_that);case PlaceNotFound():
return notFound(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaceNetworkError value)?  networkError,TResult? Function( PlaceServerError value)?  serverError,TResult? Function( PlaceParseError value)?  parseError,TResult? Function( PlaceNotFound value)?  notFound,}){
final _that = this;
switch (_that) {
case PlaceNetworkError() when networkError != null:
return networkError(_that);case PlaceServerError() when serverError != null:
return serverError(_that);case PlaceParseError() when parseError != null:
return parseError(_that);case PlaceNotFound() when notFound != null:
return notFound(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? message)?  networkError,TResult Function( int statusCode,  String? message)?  serverError,TResult Function( String? message)?  parseError,TResult Function()?  notFound,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaceNetworkError() when networkError != null:
return networkError(_that.message);case PlaceServerError() when serverError != null:
return serverError(_that.statusCode,_that.message);case PlaceParseError() when parseError != null:
return parseError(_that.message);case PlaceNotFound() when notFound != null:
return notFound();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? message)  networkError,required TResult Function( int statusCode,  String? message)  serverError,required TResult Function( String? message)  parseError,required TResult Function()  notFound,}) {final _that = this;
switch (_that) {
case PlaceNetworkError():
return networkError(_that.message);case PlaceServerError():
return serverError(_that.statusCode,_that.message);case PlaceParseError():
return parseError(_that.message);case PlaceNotFound():
return notFound();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? message)?  networkError,TResult? Function( int statusCode,  String? message)?  serverError,TResult? Function( String? message)?  parseError,TResult? Function()?  notFound,}) {final _that = this;
switch (_that) {
case PlaceNetworkError() when networkError != null:
return networkError(_that.message);case PlaceServerError() when serverError != null:
return serverError(_that.statusCode,_that.message);case PlaceParseError() when parseError != null:
return parseError(_that.message);case PlaceNotFound() when notFound != null:
return notFound();case _:
  return null;

}
}

}

/// @nodoc


class PlaceNetworkError implements PlaceFailure {
  const PlaceNetworkError({this.message});
  

 final  String? message;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceNetworkErrorCopyWith<PlaceNetworkError> get copyWith => _$PlaceNetworkErrorCopyWithImpl<PlaceNetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNetworkError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlaceFailure.networkError(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaceNetworkErrorCopyWith<$Res> implements $PlaceFailureCopyWith<$Res> {
  factory $PlaceNetworkErrorCopyWith(PlaceNetworkError value, $Res Function(PlaceNetworkError) _then) = _$PlaceNetworkErrorCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$PlaceNetworkErrorCopyWithImpl<$Res>
    implements $PlaceNetworkErrorCopyWith<$Res> {
  _$PlaceNetworkErrorCopyWithImpl(this._self, this._then);

  final PlaceNetworkError _self;
  final $Res Function(PlaceNetworkError) _then;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(PlaceNetworkError(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PlaceServerError implements PlaceFailure {
  const PlaceServerError({required this.statusCode, this.message});
  

 final  int statusCode;
 final  String? message;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceServerErrorCopyWith<PlaceServerError> get copyWith => _$PlaceServerErrorCopyWithImpl<PlaceServerError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceServerError&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,message);

@override
String toString() {
  return 'PlaceFailure.serverError(statusCode: $statusCode, message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaceServerErrorCopyWith<$Res> implements $PlaceFailureCopyWith<$Res> {
  factory $PlaceServerErrorCopyWith(PlaceServerError value, $Res Function(PlaceServerError) _then) = _$PlaceServerErrorCopyWithImpl;
@useResult
$Res call({
 int statusCode, String? message
});




}
/// @nodoc
class _$PlaceServerErrorCopyWithImpl<$Res>
    implements $PlaceServerErrorCopyWith<$Res> {
  _$PlaceServerErrorCopyWithImpl(this._self, this._then);

  final PlaceServerError _self;
  final $Res Function(PlaceServerError) _then;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusCode = null,Object? message = freezed,}) {
  return _then(PlaceServerError(
statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PlaceParseError implements PlaceFailure {
  const PlaceParseError({this.message});
  

 final  String? message;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceParseErrorCopyWith<PlaceParseError> get copyWith => _$PlaceParseErrorCopyWithImpl<PlaceParseError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceParseError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlaceFailure.parseError(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaceParseErrorCopyWith<$Res> implements $PlaceFailureCopyWith<$Res> {
  factory $PlaceParseErrorCopyWith(PlaceParseError value, $Res Function(PlaceParseError) _then) = _$PlaceParseErrorCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$PlaceParseErrorCopyWithImpl<$Res>
    implements $PlaceParseErrorCopyWith<$Res> {
  _$PlaceParseErrorCopyWithImpl(this._self, this._then);

  final PlaceParseError _self;
  final $Res Function(PlaceParseError) _then;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(PlaceParseError(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PlaceNotFound implements PlaceFailure {
  const PlaceNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceFailure.notFound()';
}


}




// dart format on

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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaceNetworkFailure value)?  networkError,TResult Function( PlaceServerFailure value)?  serverError,TResult Function( PlaceParseFailure value)?  parseError,TResult Function( PlaceNotFoundFailure value)?  notFound,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaceNetworkFailure() when networkError != null:
return networkError(_that);case PlaceServerFailure() when serverError != null:
return serverError(_that);case PlaceParseFailure() when parseError != null:
return parseError(_that);case PlaceNotFoundFailure() when notFound != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaceNetworkFailure value)  networkError,required TResult Function( PlaceServerFailure value)  serverError,required TResult Function( PlaceParseFailure value)  parseError,required TResult Function( PlaceNotFoundFailure value)  notFound,}){
final _that = this;
switch (_that) {
case PlaceNetworkFailure():
return networkError(_that);case PlaceServerFailure():
return serverError(_that);case PlaceParseFailure():
return parseError(_that);case PlaceNotFoundFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaceNetworkFailure value)?  networkError,TResult? Function( PlaceServerFailure value)?  serverError,TResult? Function( PlaceParseFailure value)?  parseError,TResult? Function( PlaceNotFoundFailure value)?  notFound,}){
final _that = this;
switch (_that) {
case PlaceNetworkFailure() when networkError != null:
return networkError(_that);case PlaceServerFailure() when serverError != null:
return serverError(_that);case PlaceParseFailure() when parseError != null:
return parseError(_that);case PlaceNotFoundFailure() when notFound != null:
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
case PlaceNetworkFailure() when networkError != null:
return networkError(_that.message);case PlaceServerFailure() when serverError != null:
return serverError(_that.statusCode,_that.message);case PlaceParseFailure() when parseError != null:
return parseError(_that.message);case PlaceNotFoundFailure() when notFound != null:
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
case PlaceNetworkFailure():
return networkError(_that.message);case PlaceServerFailure():
return serverError(_that.statusCode,_that.message);case PlaceParseFailure():
return parseError(_that.message);case PlaceNotFoundFailure():
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
case PlaceNetworkFailure() when networkError != null:
return networkError(_that.message);case PlaceServerFailure() when serverError != null:
return serverError(_that.statusCode,_that.message);case PlaceParseFailure() when parseError != null:
return parseError(_that.message);case PlaceNotFoundFailure() when notFound != null:
return notFound();case _:
  return null;

}
}

}

/// @nodoc


class PlaceNetworkFailure implements PlaceFailure {
  const PlaceNetworkFailure({this.message});
  

 final  String? message;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceNetworkFailureCopyWith<PlaceNetworkFailure> get copyWith => _$PlaceNetworkFailureCopyWithImpl<PlaceNetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNetworkFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlaceFailure.networkError(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaceNetworkFailureCopyWith<$Res> implements $PlaceFailureCopyWith<$Res> {
  factory $PlaceNetworkFailureCopyWith(PlaceNetworkFailure value, $Res Function(PlaceNetworkFailure) _then) = _$PlaceNetworkFailureCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$PlaceNetworkFailureCopyWithImpl<$Res>
    implements $PlaceNetworkFailureCopyWith<$Res> {
  _$PlaceNetworkFailureCopyWithImpl(this._self, this._then);

  final PlaceNetworkFailure _self;
  final $Res Function(PlaceNetworkFailure) _then;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(PlaceNetworkFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PlaceServerFailure implements PlaceFailure {
  const PlaceServerFailure({required this.statusCode, this.message});
  

 final  int statusCode;
 final  String? message;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceServerFailureCopyWith<PlaceServerFailure> get copyWith => _$PlaceServerFailureCopyWithImpl<PlaceServerFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceServerFailure&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,message);

@override
String toString() {
  return 'PlaceFailure.serverError(statusCode: $statusCode, message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaceServerFailureCopyWith<$Res> implements $PlaceFailureCopyWith<$Res> {
  factory $PlaceServerFailureCopyWith(PlaceServerFailure value, $Res Function(PlaceServerFailure) _then) = _$PlaceServerFailureCopyWithImpl;
@useResult
$Res call({
 int statusCode, String? message
});




}
/// @nodoc
class _$PlaceServerFailureCopyWithImpl<$Res>
    implements $PlaceServerFailureCopyWith<$Res> {
  _$PlaceServerFailureCopyWithImpl(this._self, this._then);

  final PlaceServerFailure _self;
  final $Res Function(PlaceServerFailure) _then;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusCode = null,Object? message = freezed,}) {
  return _then(PlaceServerFailure(
statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PlaceParseFailure implements PlaceFailure {
  const PlaceParseFailure({this.message});
  

 final  String? message;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceParseFailureCopyWith<PlaceParseFailure> get copyWith => _$PlaceParseFailureCopyWithImpl<PlaceParseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceParseFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlaceFailure.parseError(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaceParseFailureCopyWith<$Res> implements $PlaceFailureCopyWith<$Res> {
  factory $PlaceParseFailureCopyWith(PlaceParseFailure value, $Res Function(PlaceParseFailure) _then) = _$PlaceParseFailureCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$PlaceParseFailureCopyWithImpl<$Res>
    implements $PlaceParseFailureCopyWith<$Res> {
  _$PlaceParseFailureCopyWithImpl(this._self, this._then);

  final PlaceParseFailure _self;
  final $Res Function(PlaceParseFailure) _then;

/// Create a copy of PlaceFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(PlaceParseFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PlaceNotFoundFailure implements PlaceFailure {
  const PlaceNotFoundFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNotFoundFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceFailure.notFound()';
}


}




// dart format on

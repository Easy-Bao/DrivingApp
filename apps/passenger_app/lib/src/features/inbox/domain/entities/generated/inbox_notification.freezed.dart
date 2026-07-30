// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../inbox_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InboxNotification {

 String get id; String get title; String get message; DateTime get timestamp; String get type; bool get isRead;
/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxNotificationCopyWith<InboxNotification> get copyWith => _$InboxNotificationCopyWithImpl<InboxNotification>(this as InboxNotification, _$identity);

  /// Serializes this InboxNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.type, type) || other.type == type)&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,message,timestamp,type,isRead);

@override
String toString() {
  return 'InboxNotification(id: $id, title: $title, message: $message, timestamp: $timestamp, type: $type, isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class $InboxNotificationCopyWith<$Res>  {
  factory $InboxNotificationCopyWith(InboxNotification value, $Res Function(InboxNotification) _then) = _$InboxNotificationCopyWithImpl;
@useResult
$Res call({
 String id, String title, String message, DateTime timestamp, String type, bool isRead
});




}
/// @nodoc
class _$InboxNotificationCopyWithImpl<$Res>
    implements $InboxNotificationCopyWith<$Res> {
  _$InboxNotificationCopyWithImpl(this._self, this._then);

  final InboxNotification _self;
  final $Res Function(InboxNotification) _then;

/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? message = null,Object? timestamp = null,Object? type = null,Object? isRead = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxNotification].
extension InboxNotificationPatterns on InboxNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxNotification value)  $default,){
final _that = this;
switch (_that) {
case _InboxNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxNotification value)?  $default,){
final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String message,  DateTime timestamp,  String type,  bool isRead)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
return $default(_that.id,_that.title,_that.message,_that.timestamp,_that.type,_that.isRead);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String message,  DateTime timestamp,  String type,  bool isRead)  $default,) {final _that = this;
switch (_that) {
case _InboxNotification():
return $default(_that.id,_that.title,_that.message,_that.timestamp,_that.type,_that.isRead);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String message,  DateTime timestamp,  String type,  bool isRead)?  $default,) {final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
return $default(_that.id,_that.title,_that.message,_that.timestamp,_that.type,_that.isRead);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxNotification implements InboxNotification {
  const _InboxNotification({required this.id, required this.title, required this.message, required this.timestamp, required this.type, required this.isRead});
  factory _InboxNotification.fromJson(Map<String, dynamic> json) => _$InboxNotificationFromJson(json);

@override final  String id;
@override final  String title;
@override final  String message;
@override final  DateTime timestamp;
@override final  String type;
@override final  bool isRead;

/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxNotificationCopyWith<_InboxNotification> get copyWith => __$InboxNotificationCopyWithImpl<_InboxNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.type, type) || other.type == type)&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,message,timestamp,type,isRead);

@override
String toString() {
  return 'InboxNotification(id: $id, title: $title, message: $message, timestamp: $timestamp, type: $type, isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class _$InboxNotificationCopyWith<$Res> implements $InboxNotificationCopyWith<$Res> {
  factory _$InboxNotificationCopyWith(_InboxNotification value, $Res Function(_InboxNotification) _then) = __$InboxNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String message, DateTime timestamp, String type, bool isRead
});




}
/// @nodoc
class __$InboxNotificationCopyWithImpl<$Res>
    implements _$InboxNotificationCopyWith<$Res> {
  __$InboxNotificationCopyWithImpl(this._self, this._then);

  final _InboxNotification _self;
  final $Res Function(_InboxNotification) _then;

/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? message = null,Object? timestamp = null,Object? type = null,Object? isRead = null,}) {
  return _then(_InboxNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

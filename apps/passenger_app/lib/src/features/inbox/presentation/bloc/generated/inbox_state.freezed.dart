// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../inbox_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InboxState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InboxState()';
}


}

/// @nodoc
class $InboxStateCopyWith<$Res>  {
$InboxStateCopyWith(InboxState _, $Res Function(InboxState) __);
}


/// Adds pattern-matching-related methods to [InboxState].
extension InboxStatePatterns on InboxState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InboxInitialState value)?  initial,TResult Function( InboxLoadingState value)?  loading,TResult Function( InboxLoadedState value)?  loaded,TResult Function( InboxErrorState value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InboxInitialState() when initial != null:
return initial(_that);case InboxLoadingState() when loading != null:
return loading(_that);case InboxLoadedState() when loaded != null:
return loaded(_that);case InboxErrorState() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InboxInitialState value)  initial,required TResult Function( InboxLoadingState value)  loading,required TResult Function( InboxLoadedState value)  loaded,required TResult Function( InboxErrorState value)  error,}){
final _that = this;
switch (_that) {
case InboxInitialState():
return initial(_that);case InboxLoadingState():
return loading(_that);case InboxLoadedState():
return loaded(_that);case InboxErrorState():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InboxInitialState value)?  initial,TResult? Function( InboxLoadingState value)?  loading,TResult? Function( InboxLoadedState value)?  loaded,TResult? Function( InboxErrorState value)?  error,}){
final _that = this;
switch (_that) {
case InboxInitialState() when initial != null:
return initial(_that);case InboxLoadingState() when loading != null:
return loading(_that);case InboxLoadedState() when loaded != null:
return loaded(_that);case InboxErrorState() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<InboxNotification> notifications)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InboxInitialState() when initial != null:
return initial();case InboxLoadingState() when loading != null:
return loading();case InboxLoadedState() when loaded != null:
return loaded(_that.notifications);case InboxErrorState() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<InboxNotification> notifications)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case InboxInitialState():
return initial();case InboxLoadingState():
return loading();case InboxLoadedState():
return loaded(_that.notifications);case InboxErrorState():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<InboxNotification> notifications)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case InboxInitialState() when initial != null:
return initial();case InboxLoadingState() when loading != null:
return loading();case InboxLoadedState() when loaded != null:
return loaded(_that.notifications);case InboxErrorState() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class InboxInitialState implements InboxState {
  const InboxInitialState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxInitialState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InboxState.initial()';
}


}




/// @nodoc


class InboxLoadingState implements InboxState {
  const InboxLoadingState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxLoadingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InboxState.loading()';
}


}




/// @nodoc


class InboxLoadedState implements InboxState {
  const InboxLoadedState(final  List<InboxNotification> notifications): _notifications = notifications;
  

 final  List<InboxNotification> _notifications;
 List<InboxNotification> get notifications {
  if (_notifications is EqualUnmodifiableListView) return _notifications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notifications);
}


/// Create a copy of InboxState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxLoadedStateCopyWith<InboxLoadedState> get copyWith => _$InboxLoadedStateCopyWithImpl<InboxLoadedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxLoadedState&&const DeepCollectionEquality().equals(other._notifications, _notifications));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_notifications));

@override
String toString() {
  return 'InboxState.loaded(notifications: $notifications)';
}


}

/// @nodoc
abstract mixin class $InboxLoadedStateCopyWith<$Res> implements $InboxStateCopyWith<$Res> {
  factory $InboxLoadedStateCopyWith(InboxLoadedState value, $Res Function(InboxLoadedState) _then) = _$InboxLoadedStateCopyWithImpl;
@useResult
$Res call({
 List<InboxNotification> notifications
});




}
/// @nodoc
class _$InboxLoadedStateCopyWithImpl<$Res>
    implements $InboxLoadedStateCopyWith<$Res> {
  _$InboxLoadedStateCopyWithImpl(this._self, this._then);

  final InboxLoadedState _self;
  final $Res Function(InboxLoadedState) _then;

/// Create a copy of InboxState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? notifications = null,}) {
  return _then(InboxLoadedState(
null == notifications ? _self._notifications : notifications // ignore: cast_nullable_to_non_nullable
as List<InboxNotification>,
  ));
}


}

/// @nodoc


class InboxErrorState implements InboxState {
  const InboxErrorState(this.message);
  

 final  String message;

/// Create a copy of InboxState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxErrorStateCopyWith<InboxErrorState> get copyWith => _$InboxErrorStateCopyWithImpl<InboxErrorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxErrorState&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'InboxState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $InboxErrorStateCopyWith<$Res> implements $InboxStateCopyWith<$Res> {
  factory $InboxErrorStateCopyWith(InboxErrorState value, $Res Function(InboxErrorState) _then) = _$InboxErrorStateCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$InboxErrorStateCopyWithImpl<$Res>
    implements $InboxErrorStateCopyWith<$Res> {
  _$InboxErrorStateCopyWithImpl(this._self, this._then);

  final InboxErrorState _self;
  final $Res Function(InboxErrorState) _then;

/// Create a copy of InboxState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(InboxErrorState(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

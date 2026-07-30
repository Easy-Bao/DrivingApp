// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthEvent()';
  }
}

/// @nodoc
class $AuthEventCopyWith<$Res> {
  $AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}

/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthCheckRequested value)? checkRequested,
    TResult Function(AuthLoggedIn value)? loggedIn,
    TResult Function(AuthLoggedOut value)? loggedOut,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthCheckRequested() when checkRequested != null:
        return checkRequested(_that);
      case AuthLoggedIn() when loggedIn != null:
        return loggedIn(_that);
      case AuthLoggedOut() when loggedOut != null:
        return loggedOut(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthCheckRequested value) checkRequested,
    required TResult Function(AuthLoggedIn value) loggedIn,
    required TResult Function(AuthLoggedOut value) loggedOut,
  }) {
    final _that = this;
    switch (_that) {
      case AuthCheckRequested():
        return checkRequested(_that);
      case AuthLoggedIn():
        return loggedIn(_that);
      case AuthLoggedOut():
        return loggedOut(_that);
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthCheckRequested value)? checkRequested,
    TResult? Function(AuthLoggedIn value)? loggedIn,
    TResult? Function(AuthLoggedOut value)? loggedOut,
  }) {
    final _that = this;
    switch (_that) {
      case AuthCheckRequested() when checkRequested != null:
        return checkRequested(_that);
      case AuthLoggedIn() when loggedIn != null:
        return loggedIn(_that);
      case AuthLoggedOut() when loggedOut != null:
        return loggedOut(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? checkRequested,
    TResult Function(String token, String userId)? loggedIn,
    TResult Function()? loggedOut,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthCheckRequested() when checkRequested != null:
        return checkRequested();
      case AuthLoggedIn() when loggedIn != null:
        return loggedIn(_that.token, _that.userId);
      case AuthLoggedOut() when loggedOut != null:
        return loggedOut();
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() checkRequested,
    required TResult Function(String token, String userId) loggedIn,
    required TResult Function() loggedOut,
  }) {
    final _that = this;
    switch (_that) {
      case AuthCheckRequested():
        return checkRequested();
      case AuthLoggedIn():
        return loggedIn(_that.token, _that.userId);
      case AuthLoggedOut():
        return loggedOut();
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? checkRequested,
    TResult? Function(String token, String userId)? loggedIn,
    TResult? Function()? loggedOut,
  }) {
    final _that = this;
    switch (_that) {
      case AuthCheckRequested() when checkRequested != null:
        return checkRequested();
      case AuthLoggedIn() when loggedIn != null:
        return loggedIn(_that.token, _that.userId);
      case AuthLoggedOut() when loggedOut != null:
        return loggedOut();
      case _:
        return null;
    }
  }
}

/// @nodoc

class AuthCheckRequested implements AuthEvent {
  const AuthCheckRequested();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthCheckRequested);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthEvent.checkRequested()';
  }
}

/// @nodoc

class AuthLoggedIn implements AuthEvent {
  const AuthLoggedIn({required this.token, required this.userId});

  final String token;
  final String userId;

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthLoggedInCopyWith<AuthLoggedIn> get copyWith =>
      _$AuthLoggedInCopyWithImpl<AuthLoggedIn>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthLoggedIn &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, token, userId);

  @override
  String toString() {
    return 'AuthEvent.loggedIn(token: $token, userId: $userId)';
  }
}

/// @nodoc
abstract mixin class $AuthLoggedInCopyWith<$Res>
    implements $AuthEventCopyWith<$Res> {
  factory $AuthLoggedInCopyWith(
          AuthLoggedIn value, $Res Function(AuthLoggedIn) _then) =
      _$AuthLoggedInCopyWithImpl;
  @useResult
  $Res call({String token, String userId});
}

/// @nodoc
class _$AuthLoggedInCopyWithImpl<$Res> implements $AuthLoggedInCopyWith<$Res> {
  _$AuthLoggedInCopyWithImpl(this._self, this._then);

  final AuthLoggedIn _self;
  final $Res Function(AuthLoggedIn) _then;

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? token = null,
    Object? userId = null,
  }) {
    return _then(AuthLoggedIn(
      token: null == token
          ? _self.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class AuthLoggedOut implements AuthEvent {
  const AuthLoggedOut();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthLoggedOut);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthEvent.loggedOut()';
  }
}

// dart format on

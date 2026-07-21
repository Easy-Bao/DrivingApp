// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../fare_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FareBreakdown {
  double get baseFare;
  double get distanceCharge;
  double get timeCharge;
  double get surgeCharge;
  double get totalFare;

  /// Create a copy of FareBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FareBreakdownCopyWith<FareBreakdown> get copyWith =>
      _$FareBreakdownCopyWithImpl<FareBreakdown>(
          this as FareBreakdown, _$identity);

  /// Serializes this FareBreakdown to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FareBreakdown &&
            (identical(other.baseFare, baseFare) ||
                other.baseFare == baseFare) &&
            (identical(other.distanceCharge, distanceCharge) ||
                other.distanceCharge == distanceCharge) &&
            (identical(other.timeCharge, timeCharge) ||
                other.timeCharge == timeCharge) &&
            (identical(other.surgeCharge, surgeCharge) ||
                other.surgeCharge == surgeCharge) &&
            (identical(other.totalFare, totalFare) ||
                other.totalFare == totalFare));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, baseFare, distanceCharge,
      timeCharge, surgeCharge, totalFare);

  @override
  String toString() {
    return 'FareBreakdown(baseFare: $baseFare, distanceCharge: $distanceCharge, timeCharge: $timeCharge, surgeCharge: $surgeCharge, totalFare: $totalFare)';
  }
}

/// @nodoc
abstract mixin class $FareBreakdownCopyWith<$Res> {
  factory $FareBreakdownCopyWith(
          FareBreakdown value, $Res Function(FareBreakdown) _then) =
      _$FareBreakdownCopyWithImpl;
  @useResult
  $Res call(
      {double baseFare,
      double distanceCharge,
      double timeCharge,
      double surgeCharge,
      double totalFare});
}

/// @nodoc
class _$FareBreakdownCopyWithImpl<$Res>
    implements $FareBreakdownCopyWith<$Res> {
  _$FareBreakdownCopyWithImpl(this._self, this._then);

  final FareBreakdown _self;
  final $Res Function(FareBreakdown) _then;

  /// Create a copy of FareBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseFare = null,
    Object? distanceCharge = null,
    Object? timeCharge = null,
    Object? surgeCharge = null,
    Object? totalFare = null,
  }) {
    return _then(_self.copyWith(
      baseFare: null == baseFare
          ? _self.baseFare
          : baseFare // ignore: cast_nullable_to_non_nullable
              as double,
      distanceCharge: null == distanceCharge
          ? _self.distanceCharge
          : distanceCharge // ignore: cast_nullable_to_non_nullable
              as double,
      timeCharge: null == timeCharge
          ? _self.timeCharge
          : timeCharge // ignore: cast_nullable_to_non_nullable
              as double,
      surgeCharge: null == surgeCharge
          ? _self.surgeCharge
          : surgeCharge // ignore: cast_nullable_to_non_nullable
              as double,
      totalFare: null == totalFare
          ? _self.totalFare
          : totalFare // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [FareBreakdown].
extension FareBreakdownPatterns on FareBreakdown {
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
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FareBreakdown value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FareBreakdown() when $default != null:
        return $default(_that);
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
  TResult map<TResult extends Object?>(
    TResult Function(_FareBreakdown value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareBreakdown():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FareBreakdown value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareBreakdown() when $default != null:
        return $default(_that);
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
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(double baseFare, double distanceCharge, double timeCharge,
            double surgeCharge, double totalFare)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FareBreakdown() when $default != null:
        return $default(_that.baseFare, _that.distanceCharge, _that.timeCharge,
            _that.surgeCharge, _that.totalFare);
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
  TResult when<TResult extends Object?>(
    TResult Function(double baseFare, double distanceCharge, double timeCharge,
            double surgeCharge, double totalFare)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareBreakdown():
        return $default(_that.baseFare, _that.distanceCharge, _that.timeCharge,
            _that.surgeCharge, _that.totalFare);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(double baseFare, double distanceCharge, double timeCharge,
            double surgeCharge, double totalFare)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareBreakdown() when $default != null:
        return $default(_that.baseFare, _that.distanceCharge, _that.timeCharge,
            _that.surgeCharge, _that.totalFare);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FareBreakdown implements FareBreakdown {
  const _FareBreakdown(
      {required this.baseFare,
      required this.distanceCharge,
      required this.timeCharge,
      required this.surgeCharge,
      required this.totalFare});
  factory _FareBreakdown.fromJson(Map<String, dynamic> json) =>
      _$FareBreakdownFromJson(json);

  @override
  final double baseFare;
  @override
  final double distanceCharge;
  @override
  final double timeCharge;
  @override
  final double surgeCharge;
  @override
  final double totalFare;

  /// Create a copy of FareBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FareBreakdownCopyWith<_FareBreakdown> get copyWith =>
      __$FareBreakdownCopyWithImpl<_FareBreakdown>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FareBreakdownToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FareBreakdown &&
            (identical(other.baseFare, baseFare) ||
                other.baseFare == baseFare) &&
            (identical(other.distanceCharge, distanceCharge) ||
                other.distanceCharge == distanceCharge) &&
            (identical(other.timeCharge, timeCharge) ||
                other.timeCharge == timeCharge) &&
            (identical(other.surgeCharge, surgeCharge) ||
                other.surgeCharge == surgeCharge) &&
            (identical(other.totalFare, totalFare) ||
                other.totalFare == totalFare));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, baseFare, distanceCharge,
      timeCharge, surgeCharge, totalFare);

  @override
  String toString() {
    return 'FareBreakdown(baseFare: $baseFare, distanceCharge: $distanceCharge, timeCharge: $timeCharge, surgeCharge: $surgeCharge, totalFare: $totalFare)';
  }
}

/// @nodoc
abstract mixin class _$FareBreakdownCopyWith<$Res>
    implements $FareBreakdownCopyWith<$Res> {
  factory _$FareBreakdownCopyWith(
          _FareBreakdown value, $Res Function(_FareBreakdown) _then) =
      __$FareBreakdownCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double baseFare,
      double distanceCharge,
      double timeCharge,
      double surgeCharge,
      double totalFare});
}

/// @nodoc
class __$FareBreakdownCopyWithImpl<$Res>
    implements _$FareBreakdownCopyWith<$Res> {
  __$FareBreakdownCopyWithImpl(this._self, this._then);

  final _FareBreakdown _self;
  final $Res Function(_FareBreakdown) _then;

  /// Create a copy of FareBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? baseFare = null,
    Object? distanceCharge = null,
    Object? timeCharge = null,
    Object? surgeCharge = null,
    Object? totalFare = null,
  }) {
    return _then(_FareBreakdown(
      baseFare: null == baseFare
          ? _self.baseFare
          : baseFare // ignore: cast_nullable_to_non_nullable
              as double,
      distanceCharge: null == distanceCharge
          ? _self.distanceCharge
          : distanceCharge // ignore: cast_nullable_to_non_nullable
              as double,
      timeCharge: null == timeCharge
          ? _self.timeCharge
          : timeCharge // ignore: cast_nullable_to_non_nullable
              as double,
      surgeCharge: null == surgeCharge
          ? _self.surgeCharge
          : surgeCharge // ignore: cast_nullable_to_non_nullable
              as double,
      totalFare: null == totalFare
          ? _self.totalFare
          : totalFare // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on

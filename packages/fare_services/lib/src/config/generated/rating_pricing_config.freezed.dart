// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../rating_pricing_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RatingPricingConfig {
  double get minimumRatingThreshold;
  double get highRatingBonusMultiplier;
  double get lowRatingSurgePenaltyMultiplier;
  double get baseSurgeCap;

  /// Create a copy of RatingPricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RatingPricingConfigCopyWith<RatingPricingConfig> get copyWith =>
      _$RatingPricingConfigCopyWithImpl<RatingPricingConfig>(
          this as RatingPricingConfig, _$identity);

  /// Serializes this RatingPricingConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RatingPricingConfig &&
            (identical(other.minimumRatingThreshold, minimumRatingThreshold) ||
                other.minimumRatingThreshold == minimumRatingThreshold) &&
            (identical(other.highRatingBonusMultiplier,
                    highRatingBonusMultiplier) ||
                other.highRatingBonusMultiplier == highRatingBonusMultiplier) &&
            (identical(other.lowRatingSurgePenaltyMultiplier,
                    lowRatingSurgePenaltyMultiplier) ||
                other.lowRatingSurgePenaltyMultiplier ==
                    lowRatingSurgePenaltyMultiplier) &&
            (identical(other.baseSurgeCap, baseSurgeCap) ||
                other.baseSurgeCap == baseSurgeCap));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, minimumRatingThreshold,
      highRatingBonusMultiplier, lowRatingSurgePenaltyMultiplier, baseSurgeCap);

  @override
  String toString() {
    return 'RatingPricingConfig(minimumRatingThreshold: $minimumRatingThreshold, highRatingBonusMultiplier: $highRatingBonusMultiplier, lowRatingSurgePenaltyMultiplier: $lowRatingSurgePenaltyMultiplier, baseSurgeCap: $baseSurgeCap)';
  }
}

/// @nodoc
abstract mixin class $RatingPricingConfigCopyWith<$Res> {
  factory $RatingPricingConfigCopyWith(
          RatingPricingConfig value, $Res Function(RatingPricingConfig) _then) =
      _$RatingPricingConfigCopyWithImpl;
  @useResult
  $Res call(
      {double minimumRatingThreshold,
      double highRatingBonusMultiplier,
      double lowRatingSurgePenaltyMultiplier,
      double baseSurgeCap});
}

/// @nodoc
class _$RatingPricingConfigCopyWithImpl<$Res>
    implements $RatingPricingConfigCopyWith<$Res> {
  _$RatingPricingConfigCopyWithImpl(this._self, this._then);

  final RatingPricingConfig _self;
  final $Res Function(RatingPricingConfig) _then;

  /// Create a copy of RatingPricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minimumRatingThreshold = null,
    Object? highRatingBonusMultiplier = null,
    Object? lowRatingSurgePenaltyMultiplier = null,
    Object? baseSurgeCap = null,
  }) {
    return _then(_self.copyWith(
      minimumRatingThreshold: null == minimumRatingThreshold
          ? _self.minimumRatingThreshold
          : minimumRatingThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      highRatingBonusMultiplier: null == highRatingBonusMultiplier
          ? _self.highRatingBonusMultiplier
          : highRatingBonusMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      lowRatingSurgePenaltyMultiplier: null == lowRatingSurgePenaltyMultiplier
          ? _self.lowRatingSurgePenaltyMultiplier
          : lowRatingSurgePenaltyMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      baseSurgeCap: null == baseSurgeCap
          ? _self.baseSurgeCap
          : baseSurgeCap // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [RatingPricingConfig].
extension RatingPricingConfigPatterns on RatingPricingConfig {
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
    TResult Function(_RatingPricingConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RatingPricingConfig() when $default != null:
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
    TResult Function(_RatingPricingConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RatingPricingConfig():
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
    TResult? Function(_RatingPricingConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RatingPricingConfig() when $default != null:
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
    TResult Function(
            double minimumRatingThreshold,
            double highRatingBonusMultiplier,
            double lowRatingSurgePenaltyMultiplier,
            double baseSurgeCap)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RatingPricingConfig() when $default != null:
        return $default(
            _that.minimumRatingThreshold,
            _that.highRatingBonusMultiplier,
            _that.lowRatingSurgePenaltyMultiplier,
            _that.baseSurgeCap);
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
    TResult Function(
            double minimumRatingThreshold,
            double highRatingBonusMultiplier,
            double lowRatingSurgePenaltyMultiplier,
            double baseSurgeCap)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RatingPricingConfig():
        return $default(
            _that.minimumRatingThreshold,
            _that.highRatingBonusMultiplier,
            _that.lowRatingSurgePenaltyMultiplier,
            _that.baseSurgeCap);
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
    TResult? Function(
            double minimumRatingThreshold,
            double highRatingBonusMultiplier,
            double lowRatingSurgePenaltyMultiplier,
            double baseSurgeCap)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RatingPricingConfig() when $default != null:
        return $default(
            _that.minimumRatingThreshold,
            _that.highRatingBonusMultiplier,
            _that.lowRatingSurgePenaltyMultiplier,
            _that.baseSurgeCap);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RatingPricingConfig implements RatingPricingConfig {
  const _RatingPricingConfig(
      {this.minimumRatingThreshold = 4.5,
      this.highRatingBonusMultiplier = 1.05,
      this.lowRatingSurgePenaltyMultiplier = 1.0,
      this.baseSurgeCap = 2.5});
  factory _RatingPricingConfig.fromJson(Map<String, dynamic> json) =>
      _$RatingPricingConfigFromJson(json);

  @override
  @JsonKey()
  final double minimumRatingThreshold;
  @override
  @JsonKey()
  final double highRatingBonusMultiplier;
  @override
  @JsonKey()
  final double lowRatingSurgePenaltyMultiplier;
  @override
  @JsonKey()
  final double baseSurgeCap;

  /// Create a copy of RatingPricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RatingPricingConfigCopyWith<_RatingPricingConfig> get copyWith =>
      __$RatingPricingConfigCopyWithImpl<_RatingPricingConfig>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RatingPricingConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RatingPricingConfig &&
            (identical(other.minimumRatingThreshold, minimumRatingThreshold) ||
                other.minimumRatingThreshold == minimumRatingThreshold) &&
            (identical(other.highRatingBonusMultiplier,
                    highRatingBonusMultiplier) ||
                other.highRatingBonusMultiplier == highRatingBonusMultiplier) &&
            (identical(other.lowRatingSurgePenaltyMultiplier,
                    lowRatingSurgePenaltyMultiplier) ||
                other.lowRatingSurgePenaltyMultiplier ==
                    lowRatingSurgePenaltyMultiplier) &&
            (identical(other.baseSurgeCap, baseSurgeCap) ||
                other.baseSurgeCap == baseSurgeCap));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, minimumRatingThreshold,
      highRatingBonusMultiplier, lowRatingSurgePenaltyMultiplier, baseSurgeCap);

  @override
  String toString() {
    return 'RatingPricingConfig(minimumRatingThreshold: $minimumRatingThreshold, highRatingBonusMultiplier: $highRatingBonusMultiplier, lowRatingSurgePenaltyMultiplier: $lowRatingSurgePenaltyMultiplier, baseSurgeCap: $baseSurgeCap)';
  }
}

/// @nodoc
abstract mixin class _$RatingPricingConfigCopyWith<$Res>
    implements $RatingPricingConfigCopyWith<$Res> {
  factory _$RatingPricingConfigCopyWith(_RatingPricingConfig value,
          $Res Function(_RatingPricingConfig) _then) =
      __$RatingPricingConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double minimumRatingThreshold,
      double highRatingBonusMultiplier,
      double lowRatingSurgePenaltyMultiplier,
      double baseSurgeCap});
}

/// @nodoc
class __$RatingPricingConfigCopyWithImpl<$Res>
    implements _$RatingPricingConfigCopyWith<$Res> {
  __$RatingPricingConfigCopyWithImpl(this._self, this._then);

  final _RatingPricingConfig _self;
  final $Res Function(_RatingPricingConfig) _then;

  /// Create a copy of RatingPricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? minimumRatingThreshold = null,
    Object? highRatingBonusMultiplier = null,
    Object? lowRatingSurgePenaltyMultiplier = null,
    Object? baseSurgeCap = null,
  }) {
    return _then(_RatingPricingConfig(
      minimumRatingThreshold: null == minimumRatingThreshold
          ? _self.minimumRatingThreshold
          : minimumRatingThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      highRatingBonusMultiplier: null == highRatingBonusMultiplier
          ? _self.highRatingBonusMultiplier
          : highRatingBonusMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      lowRatingSurgePenaltyMultiplier: null == lowRatingSurgePenaltyMultiplier
          ? _self.lowRatingSurgePenaltyMultiplier
          : lowRatingSurgePenaltyMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      baseSurgeCap: null == baseSurgeCap
          ? _self.baseSurgeCap
          : baseSurgeCap // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on

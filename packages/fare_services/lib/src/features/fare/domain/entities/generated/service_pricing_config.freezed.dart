// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../service_pricing_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServicePricingConfig {
  String get serviceName;
  double get baseFare;
  double get perKmRate;
  double get perMinuteRate;
  double get minimumFare;

  /// Create a copy of ServicePricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ServicePricingConfigCopyWith<ServicePricingConfig> get copyWith =>
      _$ServicePricingConfigCopyWithImpl<ServicePricingConfig>(
          this as ServicePricingConfig, _$identity);

  /// Serializes this ServicePricingConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ServicePricingConfig &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.baseFare, baseFare) ||
                other.baseFare == baseFare) &&
            (identical(other.perKmRate, perKmRate) ||
                other.perKmRate == perKmRate) &&
            (identical(other.perMinuteRate, perMinuteRate) ||
                other.perMinuteRate == perMinuteRate) &&
            (identical(other.minimumFare, minimumFare) ||
                other.minimumFare == minimumFare));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, serviceName, baseFare, perKmRate,
      perMinuteRate, minimumFare);

  @override
  String toString() {
    return 'ServicePricingConfig(serviceName: $serviceName, baseFare: $baseFare, perKmRate: $perKmRate, perMinuteRate: $perMinuteRate, minimumFare: $minimumFare)';
  }
}

/// @nodoc
abstract mixin class $ServicePricingConfigCopyWith<$Res> {
  factory $ServicePricingConfigCopyWith(ServicePricingConfig value,
          $Res Function(ServicePricingConfig) _then) =
      _$ServicePricingConfigCopyWithImpl;
  @useResult
  $Res call(
      {String serviceName,
      double baseFare,
      double perKmRate,
      double perMinuteRate,
      double minimumFare});
}

/// @nodoc
class _$ServicePricingConfigCopyWithImpl<$Res>
    implements $ServicePricingConfigCopyWith<$Res> {
  _$ServicePricingConfigCopyWithImpl(this._self, this._then);

  final ServicePricingConfig _self;
  final $Res Function(ServicePricingConfig) _then;

  /// Create a copy of ServicePricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serviceName = null,
    Object? baseFare = null,
    Object? perKmRate = null,
    Object? perMinuteRate = null,
    Object? minimumFare = null,
  }) {
    return _then(_self.copyWith(
      serviceName: null == serviceName
          ? _self.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      baseFare: null == baseFare
          ? _self.baseFare
          : baseFare // ignore: cast_nullable_to_non_nullable
              as double,
      perKmRate: null == perKmRate
          ? _self.perKmRate
          : perKmRate // ignore: cast_nullable_to_non_nullable
              as double,
      perMinuteRate: null == perMinuteRate
          ? _self.perMinuteRate
          : perMinuteRate // ignore: cast_nullable_to_non_nullable
              as double,
      minimumFare: null == minimumFare
          ? _self.minimumFare
          : minimumFare // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [ServicePricingConfig].
extension ServicePricingConfigPatterns on ServicePricingConfig {
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
    TResult Function(_ServicePricingConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ServicePricingConfig() when $default != null:
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
    TResult Function(_ServicePricingConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ServicePricingConfig():
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
    TResult? Function(_ServicePricingConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ServicePricingConfig() when $default != null:
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
    TResult Function(String serviceName, double baseFare, double perKmRate,
            double perMinuteRate, double minimumFare)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ServicePricingConfig() when $default != null:
        return $default(_that.serviceName, _that.baseFare, _that.perKmRate,
            _that.perMinuteRate, _that.minimumFare);
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
    TResult Function(String serviceName, double baseFare, double perKmRate,
            double perMinuteRate, double minimumFare)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ServicePricingConfig():
        return $default(_that.serviceName, _that.baseFare, _that.perKmRate,
            _that.perMinuteRate, _that.minimumFare);
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
    TResult? Function(String serviceName, double baseFare, double perKmRate,
            double perMinuteRate, double minimumFare)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ServicePricingConfig() when $default != null:
        return $default(_that.serviceName, _that.baseFare, _that.perKmRate,
            _that.perMinuteRate, _that.minimumFare);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ServicePricingConfig extends ServicePricingConfig {
  const _ServicePricingConfig(
      {required this.serviceName,
      required this.baseFare,
      required this.perKmRate,
      this.perMinuteRate = 1.5,
      this.minimumFare = 25.0})
      : super._();
  factory _ServicePricingConfig.fromJson(Map<String, dynamic> json) =>
      _$ServicePricingConfigFromJson(json);

  @override
  final String serviceName;
  @override
  final double baseFare;
  @override
  final double perKmRate;
  @override
  @JsonKey()
  final double perMinuteRate;
  @override
  @JsonKey()
  final double minimumFare;

  /// Create a copy of ServicePricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ServicePricingConfigCopyWith<_ServicePricingConfig> get copyWith =>
      __$ServicePricingConfigCopyWithImpl<_ServicePricingConfig>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ServicePricingConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ServicePricingConfig &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.baseFare, baseFare) ||
                other.baseFare == baseFare) &&
            (identical(other.perKmRate, perKmRate) ||
                other.perKmRate == perKmRate) &&
            (identical(other.perMinuteRate, perMinuteRate) ||
                other.perMinuteRate == perMinuteRate) &&
            (identical(other.minimumFare, minimumFare) ||
                other.minimumFare == minimumFare));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, serviceName, baseFare, perKmRate,
      perMinuteRate, minimumFare);

  @override
  String toString() {
    return 'ServicePricingConfig(serviceName: $serviceName, baseFare: $baseFare, perKmRate: $perKmRate, perMinuteRate: $perMinuteRate, minimumFare: $minimumFare)';
  }
}

/// @nodoc
abstract mixin class _$ServicePricingConfigCopyWith<$Res>
    implements $ServicePricingConfigCopyWith<$Res> {
  factory _$ServicePricingConfigCopyWith(_ServicePricingConfig value,
          $Res Function(_ServicePricingConfig) _then) =
      __$ServicePricingConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String serviceName,
      double baseFare,
      double perKmRate,
      double perMinuteRate,
      double minimumFare});
}

/// @nodoc
class __$ServicePricingConfigCopyWithImpl<$Res>
    implements _$ServicePricingConfigCopyWith<$Res> {
  __$ServicePricingConfigCopyWithImpl(this._self, this._then);

  final _ServicePricingConfig _self;
  final $Res Function(_ServicePricingConfig) _then;

  /// Create a copy of ServicePricingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? serviceName = null,
    Object? baseFare = null,
    Object? perKmRate = null,
    Object? perMinuteRate = null,
    Object? minimumFare = null,
  }) {
    return _then(_ServicePricingConfig(
      serviceName: null == serviceName
          ? _self.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      baseFare: null == baseFare
          ? _self.baseFare
          : baseFare // ignore: cast_nullable_to_non_nullable
              as double,
      perKmRate: null == perKmRate
          ? _self.perKmRate
          : perKmRate // ignore: cast_nullable_to_non_nullable
              as double,
      perMinuteRate: null == perMinuteRate
          ? _self.perMinuteRate
          : perMinuteRate // ignore: cast_nullable_to_non_nullable
              as double,
      minimumFare: null == minimumFare
          ? _self.minimumFare
          : minimumFare // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on

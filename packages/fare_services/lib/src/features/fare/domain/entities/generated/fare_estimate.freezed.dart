// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../fare_estimate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FareEstimate {
  FareBreakdown get breakdown;
  PaymentMethod get paymentMethod;
  String get currency;
  bool get isEstimateFallback;

  /// Create a copy of FareEstimate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FareEstimateCopyWith<FareEstimate> get copyWith =>
      _$FareEstimateCopyWithImpl<FareEstimate>(
          this as FareEstimate, _$identity);

  /// Serializes this FareEstimate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FareEstimate &&
            (identical(other.breakdown, breakdown) ||
                other.breakdown == breakdown) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.isEstimateFallback, isEstimateFallback) ||
                other.isEstimateFallback == isEstimateFallback));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, breakdown, paymentMethod, currency, isEstimateFallback);

  @override
  String toString() {
    return 'FareEstimate(breakdown: $breakdown, paymentMethod: $paymentMethod, currency: $currency, isEstimateFallback: $isEstimateFallback)';
  }
}

/// @nodoc
abstract mixin class $FareEstimateCopyWith<$Res> {
  factory $FareEstimateCopyWith(
          FareEstimate value, $Res Function(FareEstimate) _then) =
      _$FareEstimateCopyWithImpl;
  @useResult
  $Res call(
      {FareBreakdown breakdown,
      PaymentMethod paymentMethod,
      String currency,
      bool isEstimateFallback});

  $FareBreakdownCopyWith<$Res> get breakdown;
}

/// @nodoc
class _$FareEstimateCopyWithImpl<$Res> implements $FareEstimateCopyWith<$Res> {
  _$FareEstimateCopyWithImpl(this._self, this._then);

  final FareEstimate _self;
  final $Res Function(FareEstimate) _then;

  /// Create a copy of FareEstimate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? breakdown = null,
    Object? paymentMethod = null,
    Object? currency = null,
    Object? isEstimateFallback = null,
  }) {
    return _then(_self.copyWith(
      breakdown: null == breakdown
          ? _self.breakdown
          : breakdown // ignore: cast_nullable_to_non_nullable
              as FareBreakdown,
      paymentMethod: null == paymentMethod
          ? _self.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as PaymentMethod,
      currency: null == currency
          ? _self.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      isEstimateFallback: null == isEstimateFallback
          ? _self.isEstimateFallback
          : isEstimateFallback // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of FareEstimate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FareBreakdownCopyWith<$Res> get breakdown {
    return $FareBreakdownCopyWith<$Res>(_self.breakdown, (value) {
      return _then(_self.copyWith(breakdown: value));
    });
  }
}

/// Adds pattern-matching-related methods to [FareEstimate].
extension FareEstimatePatterns on FareEstimate {
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
    TResult Function(_FareEstimate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FareEstimate() when $default != null:
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
    TResult Function(_FareEstimate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareEstimate():
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
    TResult? Function(_FareEstimate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareEstimate() when $default != null:
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
    TResult Function(FareBreakdown breakdown, PaymentMethod paymentMethod,
            String currency, bool isEstimateFallback)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FareEstimate() when $default != null:
        return $default(_that.breakdown, _that.paymentMethod, _that.currency,
            _that.isEstimateFallback);
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
    TResult Function(FareBreakdown breakdown, PaymentMethod paymentMethod,
            String currency, bool isEstimateFallback)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareEstimate():
        return $default(_that.breakdown, _that.paymentMethod, _that.currency,
            _that.isEstimateFallback);
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
    TResult? Function(FareBreakdown breakdown, PaymentMethod paymentMethod,
            String currency, bool isEstimateFallback)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FareEstimate() when $default != null:
        return $default(_that.breakdown, _that.paymentMethod, _that.currency,
            _that.isEstimateFallback);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FareEstimate implements FareEstimate {
  const _FareEstimate(
      {required this.breakdown,
      this.paymentMethod = PaymentMethod.cashOnHand,
      this.currency = 'PHP',
      this.isEstimateFallback = false});
  factory _FareEstimate.fromJson(Map<String, dynamic> json) =>
      _$FareEstimateFromJson(json);

  @override
  final FareBreakdown breakdown;
  @override
  @JsonKey()
  final PaymentMethod paymentMethod;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final bool isEstimateFallback;

  /// Create a copy of FareEstimate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FareEstimateCopyWith<_FareEstimate> get copyWith =>
      __$FareEstimateCopyWithImpl<_FareEstimate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FareEstimateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FareEstimate &&
            (identical(other.breakdown, breakdown) ||
                other.breakdown == breakdown) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.isEstimateFallback, isEstimateFallback) ||
                other.isEstimateFallback == isEstimateFallback));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, breakdown, paymentMethod, currency, isEstimateFallback);

  @override
  String toString() {
    return 'FareEstimate(breakdown: $breakdown, paymentMethod: $paymentMethod, currency: $currency, isEstimateFallback: $isEstimateFallback)';
  }
}

/// @nodoc
abstract mixin class _$FareEstimateCopyWith<$Res>
    implements $FareEstimateCopyWith<$Res> {
  factory _$FareEstimateCopyWith(
          _FareEstimate value, $Res Function(_FareEstimate) _then) =
      __$FareEstimateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {FareBreakdown breakdown,
      PaymentMethod paymentMethod,
      String currency,
      bool isEstimateFallback});

  @override
  $FareBreakdownCopyWith<$Res> get breakdown;
}

/// @nodoc
class __$FareEstimateCopyWithImpl<$Res>
    implements _$FareEstimateCopyWith<$Res> {
  __$FareEstimateCopyWithImpl(this._self, this._then);

  final _FareEstimate _self;
  final $Res Function(_FareEstimate) _then;

  /// Create a copy of FareEstimate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? breakdown = null,
    Object? paymentMethod = null,
    Object? currency = null,
    Object? isEstimateFallback = null,
  }) {
    return _then(_FareEstimate(
      breakdown: null == breakdown
          ? _self.breakdown
          : breakdown // ignore: cast_nullable_to_non_nullable
              as FareBreakdown,
      paymentMethod: null == paymentMethod
          ? _self.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as PaymentMethod,
      currency: null == currency
          ? _self.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      isEstimateFallback: null == isEstimateFallback
          ? _self.isEstimateFallback
          : isEstimateFallback // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of FareEstimate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FareBreakdownCopyWith<$Res> get breakdown {
    return $FareBreakdownCopyWith<$Res>(_self.breakdown, (value) {
      return _then(_self.copyWith(breakdown: value));
    });
  }
}

// dart format on

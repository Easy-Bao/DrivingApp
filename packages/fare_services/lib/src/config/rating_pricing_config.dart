import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/rating_pricing_config.freezed.dart';
part 'generated/rating_pricing_config.g.dart';

@freezed
abstract class RatingPricingConfig with _$RatingPricingConfig {
  const factory RatingPricingConfig({
    @Default(4.5) double minimumRatingThreshold,
    @Default(1.05) double highRatingBonusMultiplier,
    @Default(1.0) double lowRatingSurgePenaltyMultiplier,
    @Default(2.5) double baseSurgeCap,
  }) = _RatingPricingConfig;

  factory RatingPricingConfig.fromJson(Map<String, dynamic> json) =>
      _$RatingPricingConfigFromJson(json);
}

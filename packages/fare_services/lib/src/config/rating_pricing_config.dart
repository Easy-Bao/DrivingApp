import 'package:freezed_annotation/freezed_annotation.dart';

part 'rating_pricing_config.freezed.dart';
part 'rating_pricing_config.g.dart';

///TODO: No default here should based on fare services server
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

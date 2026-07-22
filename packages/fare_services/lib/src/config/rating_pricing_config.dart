import 'package:equatable/equatable.dart';

class RatingPricingConfig extends Equatable {
  final double minimumRatingThreshold;
  final double highRatingBonusMultiplier;
  final double lowRatingSurgePenaltyMultiplier;
  final double baseSurgeCap;

  const RatingPricingConfig({
    required this.minimumRatingThreshold,
    required this.highRatingBonusMultiplier,
    required this.lowRatingSurgePenaltyMultiplier,
    required this.baseSurgeCap,
  });

  factory RatingPricingConfig.fromJson(Map<String, dynamic> json) {
    return RatingPricingConfig(
      minimumRatingThreshold:
          (json['minimumRatingThreshold'] as num?)?.toDouble() ?? 4.5,
      highRatingBonusMultiplier:
          (json['highRatingBonusMultiplier'] as num?)?.toDouble() ?? 1.05,
      lowRatingSurgePenaltyMultiplier:
          (json['lowRatingSurgePenaltyMultiplier'] as num?)?.toDouble() ?? 1.0,
      baseSurgeCap: (json['baseSurgeCap'] as num?)?.toDouble() ?? 2.5,
    );
  }

  @override
  List<Object?> get props => [
        minimumRatingThreshold,
        highRatingBonusMultiplier,
        lowRatingSurgePenaltyMultiplier,
        baseSurgeCap,
      ];
}

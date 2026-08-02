import 'package:equatable/equatable.dart';

class RatingPricingConfig extends Equatable {
  final double minimumRatingThreshold;
  final double highRatingBonusMultiplier;
  final double lowRatingSurgePenaltyMultiplier;
  final double baseSurgeCap;

  const RatingPricingConfig({
    this.minimumRatingThreshold = 4.5,
    this.highRatingBonusMultiplier = 1.05,
    this.lowRatingSurgePenaltyMultiplier = 1.0,
    this.baseSurgeCap = 2.5,
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

  Map<String, dynamic> toJson() {
    return {
      'minimumRatingThreshold': minimumRatingThreshold,
      'highRatingBonusMultiplier': highRatingBonusMultiplier,
      'lowRatingSurgePenaltyMultiplier': lowRatingSurgePenaltyMultiplier,
      'baseSurgeCap': baseSurgeCap,
    };
  }

  @override
  List<Object?> get props => [
    minimumRatingThreshold,
    highRatingBonusMultiplier,
    lowRatingSurgePenaltyMultiplier,
    baseSurgeCap,
  ];
}

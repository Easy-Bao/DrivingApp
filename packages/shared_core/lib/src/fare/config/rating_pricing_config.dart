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
      minimumRatingThreshold: _requiredNumber(json, 'minimumRatingThreshold'),
      highRatingBonusMultiplier: _requiredNumber(
        json,
        'highRatingBonusMultiplier',
      ),
      lowRatingSurgePenaltyMultiplier: _requiredNumber(
        json,
        'lowRatingSurgePenaltyMultiplier',
      ),
      baseSurgeCap: _requiredNumber(json, 'baseSurgeCap'),
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

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Missing numeric pricing configuration: $key');
  }
  return value.toDouble();
}

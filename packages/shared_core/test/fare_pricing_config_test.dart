import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('parses the complete server pricing configuration', () {
    final model = FareServiceModel.fromJson(const {
      'id': 'solo',
      'serviceName': 'Solo Ride',
      'baseFare': 25.0,
      'perKmRate': 1.0,
      'perMinuteRate': 0.5,
      'ratingPricingConfig': {
        'minimumRatingThreshold': 4.5,
        'highRatingBonusMultiplier': 1.05,
        'lowRatingSurgePenaltyMultiplier': 1.0,
        'baseSurgeCap': 2.5,
      },
    });

    expect(model.serviceName, 'Solo Ride');
    expect(model.perMinuteRate, 0.5);
    expect(model.ratingConfig.minimumRatingThreshold, 4.5);
  });

  test('rejects incomplete server pricing configuration', () {
    expect(() => RatingPricingConfig.fromJson(const {}), throwsFormatException);
  });

  test('rejects incomplete fare result responses', () {
    expect(() => FareResult.fromJson(const {}), throwsFormatException);
  });
}

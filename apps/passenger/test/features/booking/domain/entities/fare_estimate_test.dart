import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/domain/entities/fare_estimate.dart';

void main() {
  test('destructures the complete fare payload into numeric fields', () {
    final estimate = FareEstimate.fromJson(const {
      'base_fare': 50,
      'distance_charge': 125.5,
      'time_charge': 30,
      'surge_charge': 10,
      'total_fare': 215.5,
    });

    expect(estimate.baseFare, 50);
    expect(estimate.distanceCharge, 125.5);
    expect(estimate.timeCharge, 30);
    expect(estimate.surgeCharge, 10);
    expect(estimate.totalFare, 215.5);
  });

  test('rejects missing and non-numeric fare components', () {
    expect(
      () => FareEstimate.fromJson(const {
        'base_fare': 50,
        'distance_charge': 125.5,
        'time_charge': 30,
        'surge_charge': 10,
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => FareEstimate.fromJson(const {
        'base_fare': '50',
        'distance_charge': 125.5,
        'time_charge': 30,
        'surge_charge': 10,
        'total_fare': 215.5,
      }),
      throwsA(isA<FormatException>()),
    );
  });
}

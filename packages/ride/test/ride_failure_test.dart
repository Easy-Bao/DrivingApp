import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:ride/ride.dart';

void main() {
  test('keeps ride workflow failures typed and presentation-safe', () {
    expect(
      FailureMapper.fromException(const NoDriversAvailableFailure()),
      isA<NoDriversAvailableFailure>(),
    );
    expect(
      ErrorHandler.getErrorMessage(const RouteCalculationFailure()),
      'Unable to calculate route and fare right now. Please re-select your destination.',
    );
    expect(
      ErrorHandler.getErrorMessage(const PaymentDeclinedFailure()),
      'We could not process your payment. Your account was not charged. Please try another payment method.',
    );
  });
}

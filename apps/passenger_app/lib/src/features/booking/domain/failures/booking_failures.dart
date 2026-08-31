import 'package:foundation/foundation.dart';

class NoDriversAvailableFailure extends Failure {
  const NoDriversAvailableFailure()
    : super(
        'All nearby drivers are currently busy. Please adjust your pickup point or try again shortly.',
      );
}

class RouteCalculationFailure extends Failure {
  const RouteCalculationFailure()
    : super(
        'Unable to calculate route and fare right now. Please re-select your destination.',
      );
}

class PaymentDeclinedFailure extends Failure {
  const PaymentDeclinedFailure()
    : super(
        'We could not process your payment. Your account was not charged. Please try another payment method.',
      );
}

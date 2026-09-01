import 'package:foundation/foundation.dart';

class const NoDriversAvailableFailure() extends Failure {
  this
    : super(
        'All nearby drivers are currently busy. Please adjust your pickup point or try again shortly.',
      );
}

class const RouteCalculationFailure() extends Failure {
  this
    : super(
        'Unable to calculate route and fare right now. Please re-select your destination.',
      );
}

class const PaymentDeclinedFailure() extends Failure {
  this
    : super(
        'We could not process your payment. Your account was not charged. Please try another payment method.',
      );
}

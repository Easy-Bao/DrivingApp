import 'package:foundation/foundation.dart';

class const NoDriversAvailableFailure() extends Failure {
  this
    : super(
        'No drivers available nearby. Adjust your pickup or try again shortly.',
      );
}

class const RouteCalculationFailure() extends Failure {
  this
    : super(
        "Couldn't calculate route and fare. Re-select your destination.",
      );
}

class const PaymentDeclinedFailure() extends Failure {
  this
    : super(
        "Payment couldn't be processed. You were not charged. Try another payment method.",
      );
}

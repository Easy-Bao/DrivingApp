import 'package:foundation/foundation.dart';

class const RouteCalculationFailure() extends Failure {
  this
    : super(
        'Unable to calculate route and fare right now. Please re-select your destination.',
      );
}

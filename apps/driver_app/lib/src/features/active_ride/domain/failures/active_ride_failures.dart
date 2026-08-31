import 'package:foundation/foundation.dart';

class RouteCalculationFailure extends Failure {
  const RouteCalculationFailure()
    : super(
        'Unable to calculate route and fare right now. Please re-select your destination.',
      );
}

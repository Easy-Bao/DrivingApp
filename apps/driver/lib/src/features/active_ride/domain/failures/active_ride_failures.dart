import 'package:foundation/foundation.dart';

class const RouteCalculationFailure() extends Failure {
  this
    : super(
        "Couldn't calculate route and fare. Re-select your destination.",
      );
}

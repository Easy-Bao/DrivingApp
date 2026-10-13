import 'package:foundation/foundation.dart';

class const RideNotFoundFailure() extends Failure {
  this : super('This trip is no longer available.');
}

class const RouteCalculationFailure() extends Failure {
  this
    : super("Couldn't calculate route and fare. Re-select your destination.");
}

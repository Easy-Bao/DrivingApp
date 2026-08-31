import 'package:foundation/foundation.dart';

class LocationFailure extends Failure {
  const LocationFailure([
    super.message =
        'Unable to get an accurate location. Please move to an open area or enable high-accuracy GPS.',
  ]);
}

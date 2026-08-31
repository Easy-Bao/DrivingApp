import 'package:maps/maps.dart';

final class CurrentLocationFailure extends LocationFailure {
  const CurrentLocationFailure([
    super.message = 'The current device location is unavailable.',
  ]);
}

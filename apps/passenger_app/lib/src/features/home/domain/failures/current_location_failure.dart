import 'package:shared_core/shared_core.dart';

final class CurrentLocationFailure extends Failure {
  const CurrentLocationFailure([
    super.message = 'The current device location is unavailable.',
  ]);
}

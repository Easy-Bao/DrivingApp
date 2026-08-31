import 'package:foundation/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test('keeps location failure ownership in maps', () {
    expect(
      ErrorHandler.getErrorMessage(const LocationFailure()),
      'Unable to get an accurate location. Please move to an open area or enable high-accuracy GPS.',
    );
  });
}

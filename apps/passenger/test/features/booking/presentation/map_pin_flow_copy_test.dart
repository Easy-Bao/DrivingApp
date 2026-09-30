import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/presentation/view/map_pin_page.dart';

void main() {
  test('keeps pickup copy for the booking map-pin flow', () {
    expect(MapPinFlow.pickup.locationLabel, 'Pickup location');
    expect(MapPinFlow.pickup.confirmationLabel, 'Confirm pickup location');
  });

  test('identifies the saved-place map-pin flow', () {
    expect(MapPinFlow.savedPlace.locationLabel, 'Saved place location');
    expect(
      MapPinFlow.savedPlace.confirmationLabel,
      'Confirm saved place location',
    );
  });
}

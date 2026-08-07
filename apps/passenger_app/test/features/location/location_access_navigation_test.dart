import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/location/location_access_navigation.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';

void main() {
  test('sends a restored Home route to the location gate on first launch', () {
    final destination = locationAccessDestinationName(
      currentPath: HomeRoutes.fullHomePath,
      accessState: const LocationAccessUnavailable(accessState: .denied),
    );

    expect(destination, LocationRoutes.gate);
  });

  test('leaves the first-launch gate visible while access is unavailable', () {
    final destination = locationAccessDestinationName(
      currentPath: LocationRoutes.fullGatePath,
      accessState: const LocationAccessUnavailable(
        accessState: .serviceDisabled,
      ),
    );

    expect(destination, isNull);
  });

  test('continues to Home when location access becomes ready', () {
    final destination = locationAccessDestinationName(
      currentPath: LocationRoutes.fullGatePath,
      accessState: const LocationAccessReady(),
    );

    expect(destination, HomeRoutes.home);
  });

  test('honors Not now until the location access state changes', () {
    final destination = locationAccessDestinationName(
      currentPath: HomeRoutes.fullHomePath,
      accessState: const LocationAccessUnavailable(
        accessState: .denied,
        isPromptSuppressed: true,
      ),
    );

    expect(destination, isNull);
  });
}

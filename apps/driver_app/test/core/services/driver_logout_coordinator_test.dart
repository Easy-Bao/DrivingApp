import 'package:driver_app/src/core/services/driver_logout_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clears the session even when best-effort cleanup fails', () async {
    final completedSteps = <String>[];
    final coordinator = DriverLogoutCoordinator(
      forceOffline: () async {
        completedSteps.add('offline');
        throw StateError('availability unavailable');
      },
      stopTelemetry: () async {
        completedSteps.add('telemetry');
        throw StateError('telemetry unavailable');
      },
      clearSession: () async => completedSteps.add('session'),
    );

    await coordinator.logout();

    expect(completedSteps, ['offline', 'telemetry', 'session']);
  });
}

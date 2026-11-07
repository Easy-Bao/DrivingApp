import 'package:driver/src/features/auth/domain/services/logout_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clears the session even when best-effort cleanup fails', () async {
    final completedSteps = <String>[];
    final coordinator = LogoutCoordinator(
      forceOffline: () async {
        completedSteps.add('offline');
        throw StateError('availability unavailable');
      },
      stopTelemetry: () async {
        completedSteps.add('telemetry');
        throw StateError('telemetry unavailable');
      },
      disconnectRealtime: () async {
        completedSteps.add('realtime');
        throw StateError('socket unavailable');
      },
      clearLocationSpool: () async {
        completedSteps.add('spool');
        throw StateError('storage unavailable');
      },
      clearSession: () async => completedSteps.add('session'),
    );

    await coordinator.logout();

    expect(completedSteps, [
      'offline',
      'telemetry',
      'realtime',
      'spool',
      'session',
    ]);
  });
}

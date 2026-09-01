import 'dart:developer' as developer;

typedef DriverLogoutStep = Future<void> Function();

/// Runs the driver cleanup sequence before the authenticated session ends.
///
/// Best-effort availability and telemetry cleanup must not prevent the session
/// from being cleared. Session cleanup remains the final required step and its
/// error is allowed to reach the caller.
final class const DriverLogoutCoordinator({
  required DriverLogoutStep forceOffline,
  required DriverLogoutStep stopTelemetry,
  required DriverLogoutStep clearSession,
}) {
  this
    : _forceOffline = forceOffline,
      _stopTelemetry = stopTelemetry,
      _clearSession = clearSession;

  final DriverLogoutStep _forceOffline;
  final DriverLogoutStep _stopTelemetry;
  final DriverLogoutStep _clearSession;

  Future<void> logout() async {
    try {
      await _forceOffline();
    } catch (error, stackTrace) {
      developer.log(
        'Unable to clear driver availability during logout.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _stopTelemetry();
    } catch (error, stackTrace) {
      developer.log(
        'Unable to stop driver telemetry during logout.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _clearSession();
  }
}

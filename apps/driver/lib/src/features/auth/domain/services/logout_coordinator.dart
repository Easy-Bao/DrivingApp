import 'dart:developer' as developer;

typedef LogoutStep = Future<void> Function();

/// Best-effort availability and telemetry cleanup must not prevent the session
/// from being cleared. Session cleanup remains the final required step and its
/// error is allowed to reach the caller.
final class const LogoutCoordinator({
  required this._forceOffline,
  required this._stopTelemetry,
  required this._clearLocationSpool,
  required this._clearSession,
}) {
  final LogoutStep _forceOffline;
  final LogoutStep _stopTelemetry;
  final LogoutStep _clearLocationSpool;
  final LogoutStep _clearSession;

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

    // Queued points belong to this driver; replaying them under the next
    // account's token would attribute them to the wrong person.
    try {
      await _clearLocationSpool();
    } catch (error, stackTrace) {
      developer.log(
        'Unable to clear queued driver locations during logout.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _clearSession();
  }
}

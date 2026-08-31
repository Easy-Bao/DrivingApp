import 'dart:async';

enum AppLifecycleStatus { foreground, background }

/// Owns the app lifecycle state shared by route-level work.
///
/// The Flutter application root is the only object that translates platform
/// lifecycle callbacks into this coordinator. Feature pages subscribe to the
/// resulting stream so timers, realtime sockets, and foreground refreshes do
/// not each register their own platform observer.
final class AppLifecycleCoordinator {
  AppLifecycleCoordinator({bool initiallyForeground = true})
    : _isForeground = initiallyForeground;

  final _changes = StreamController<AppLifecycleStatus>.broadcast(sync: true);
  bool _isForeground;

  bool get isForeground => _isForeground;

  Stream<AppLifecycleStatus> get changes => _changes.stream;

  void update({required bool isForeground}) {
    if (_isForeground == isForeground || _changes.isClosed) return;
    _isForeground = isForeground;
    _changes.add(
      isForeground
          ? AppLifecycleStatus.foreground
          : AppLifecycleStatus.background,
    );
  }

  Future<void> dispose() => _changes.close();
}

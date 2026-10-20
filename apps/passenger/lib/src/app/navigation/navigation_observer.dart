import 'dart:async';

import 'package:flutter/material.dart';

/// Booking pages are siblings of the stateful shell, so a route observer
/// attached only to the home branch cannot see their pop or removal. The home
/// page uses this stream to refresh when either navigation path returns.
final class AppNavigationObserver extends NavigatorObserver {
  final _routePopEvents = StreamController<void>.broadcast(sync: true);

  Stream<void> get routePopEvents => _routePopEvents.stream;

  Future<void> dispose() => _routePopEvents.close();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (!_routePopEvents.isClosed) {
      _routePopEvents.add(null);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (!_routePopEvents.isClosed) {
      _routePopEvents.add(null);
    }
  }
}

final appNavigationObserver = AppNavigationObserver();

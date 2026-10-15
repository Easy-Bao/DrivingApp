import 'dart:async';

import 'package:flutter/material.dart';

/// Notifies persistent shell pages when a root-level flow is dismissed.
///
/// Booking pages are siblings of the stateful shell, so a route observer
/// attached only to the home branch cannot see their pop. The home page uses
/// this stream to refresh its pickup snapshot when the flow returns.
final class PassengerNavigationObserver extends NavigatorObserver {
  final _routePopEvents = StreamController<void>.broadcast(sync: true);

  Stream<void> get routePopEvents => _routePopEvents.stream;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (!_routePopEvents.isClosed) {
      _routePopEvents.add(null);
    }
  }
}

final passengerNavigationObserver = PassengerNavigationObserver();

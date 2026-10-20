import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MapWidget;
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart';

void main() {
  testWidgets('covers the native map until its first loaded event', (
    tester,
  ) async {
    final platform = _TestMapPlatform();
    MapboxMapsFlutterPlatform.instance = platform;
    var loadedCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapProvider.buildMapView(
            latitude: 14.5,
            longitude: 120.9,
            onMapLoaded: () => loadedCalls++,
          ),
        ),
      ),
    );
    expect(find.text('Loading map…'), findsOneWidget);
    expect(loadedCalls, 0);
    expect(find.byType(MapWidget), findsOneWidget);
    platform.onMapEvent!(_loadedEvent());
    await tester.pump();
    expect(find.text('Loading map…'), findsNothing);
    expect(loadedCalls, 1);
    platform.onMapEvent!(_loadedEvent());
    expect(loadedCalls, 1);
    expect(find.byType(MapWidget), findsOneWidget);
    platform.onMapEvent!(
      MapLoadingErrorEventData(
        type: MapLoadErrorType.TILE,
        message: 'Later tile failure',
        timestamp: 0,
      ),
    );
    await tester.pump();
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('offers retry on initial failure and ignores old map events', (
    tester,
  ) async {
    final platform = _TestMapPlatform();
    MapboxMapsFlutterPlatform.instance = platform;
    var loadedCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapProvider.buildMapView(
            latitude: 14.5,
            longitude: 120.9,
            onMapLoaded: () => loadedCalls++,
          ),
        ),
      ),
    );
    final oldMapEvent = platform.onMapEvent!;
    final oldKey = tester.widget<MapWidget>(find.byType(MapWidget)).key;
    oldMapEvent(
      MapLoadingErrorEventData(
        type: MapLoadErrorType.STYLE,
        message: 'Network unavailable',
        timestamp: 0,
      ),
    );
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(tester.widget<MapWidget>(find.byType(MapWidget)).key, isNot(oldKey));
    expect(find.text('Loading map…'), findsOneWidget);
    oldMapEvent(_loadedEvent());
    await tester.pump();
    expect(loadedCalls, 0);
    expect(find.text('Loading map…'), findsOneWidget);
    platform.onMapEvent!(_loadedEvent());
    await tester.pump();
    expect(find.text('Loading map…'), findsNothing);
  });

  testWidgets('buildMapView preserves and forwards camera padding', (
    tester,
  ) async {
    const testPadding = EdgeInsets.fromLTRB(10, 20, 30, 40);
    final platform = _TestMapPlatform();
    MapboxMapsFlutterPlatform.instance = platform;

    final mapView = MapProvider.buildMapView(
      latitude: 14.5995,
      longitude: 120.9842,
      padding: testPadding,
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: mapView)));

    final viewport = platform.viewport! as CameraViewportState;
    expect(viewport.padding, testPadding);
    expect(viewport.center!.coordinates.lat, 14.5995);
    expect(viewport.center!.coordinates.lng, 120.9842);
    expect(viewport.zoom, 14.0);
  });
}

final class _TestMapPlatform extends MapboxMapsFlutterPlatform {
  ViewportState? viewport;
  void Function(MapEvent)? onMapEvent;

  @override
  Widget buildView({
    required String styleUri,
    PlatformMapCreatedCallback? onMapCreated,
    ViewportState? viewport,
    ViewportTransition? viewportTransition,
    void Function(bool)? viewportTransitionCompletion,
    void Function(MapEvent)? onMapEvent,
    MapOptions? mapOptions,
    bool? textureView,
    // ignore: experimental_member_use
    required AndroidPlatformViewHostingMode androidHostingMode,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    bool? isOpaque = true,
  }) {
    this.viewport = viewport;
    this.onMapEvent = onMapEvent;
    return const SizedBox.expand();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MapLoadedEventData _loadedEvent() => MapLoadedEventData(
  timeInterval: EventTimeInterval(
    begin: DateTime.utc(2026),
    end: DateTime.utc(2026),
  ),
);

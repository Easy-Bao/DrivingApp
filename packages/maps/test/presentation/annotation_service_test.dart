import 'dart:async';

import 'package:design_system/design_system.dart'
    show AppPalette, AppStatusColors;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('annotation manager cleanup', () {
    for (final removalFails in [false, true]) {
      test('removes an owned manager once (failure: $removalFails)', () async {
        final annotations = _TestAnnotations(removalFails: removalFails);
        final controller = AppMapController(
          mapbox.MapboxMap(_TestMap(annotations)),
        );
        final manager = await MapAnnotationService.addMarker(
          controller,
          7.8,
          123.4,
        );

        await MapAnnotationService.clearAnnotations(manager);
        await MapAnnotationService.clearAnnotations(manager);

        expect(annotations.removalCalls, 1);
        expect(annotations.point.deleteAllCalls, 0);
      });
    }

    test('concurrent cleanup waits for the same removal', () async {
      final removal = Completer<void>();
      final annotations = _TestAnnotations(removal: removal);
      final controller = AppMapController(
        mapbox.MapboxMap(_TestMap(annotations)),
      );
      final manager = await MapAnnotationService.addMarker(
        controller,
        7.8,
        123.4,
      );
      var secondCompleted = false;

      final first = MapAnnotationService.clearAnnotations(manager);
      final second = MapAnnotationService.clearAnnotations(manager).then((_) {
        secondCompleted = true;
      });
      await Future<void>.delayed(Duration.zero);
      final callsBeforeCompletion = annotations.removalCalls;
      final completedBeforeRemoval = secondCompleted;
      removal.complete();
      await Future.wait([first, second]);

      expect(callsBeforeCompletion, 1);
      expect(completedBeforeRemoval, isFalse);
      expect(annotations.point.deleteAllCalls, 0);
    });

    test('clears an externally created manager once', () async {
      final point = _TestPoint();
      final manager = mapbox.PointAnnotationManager(point);

      await MapAnnotationService.clearAnnotations(manager);
      await MapAnnotationService.clearAnnotations(manager);

      expect(point.deleteAllCalls, 1);
    });
  });

  test('trip markers keep one screen-space size and role colors', () {
    expect(TripMapMarkerStyle.pinIconSize, greaterThan(1.0));
    expect(TripMapMarkerStyle.colorFor(isOrigin: true), AppPalette.obsidian);
    expect(
      TripMapMarkerStyle.colorFor(isOrigin: false),
      AppStatusColors.success,
    );
  });

  test('marker motion follows the shortest bearing arc', () {
    expect(
      MapMarkerMotion.interpolateBearing(350, 10, 0.5),
      closeTo(0, 0.0001),
    );
    expect(
      MapMarkerMotion.bearingBetween(
        startLatitude: 7.8,
        startLongitude: 123.4,
        targetLatitude: 7.8,
        targetLongitude: 123.5,
      ),
      closeTo(89.99, 0.5),
    );
  });
}

class _TestMap(this.annotations) implements MapboxMapPlatformInterface {
  @override
  final AnnotationManagerPlatformInterface annotations;

  @override
  final StylePlatformInterface style = _TestStyle();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestStyle implements StylePlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAnnotations({this.removalFails = false, this.removal})
    implements AnnotationManagerPlatformInterface {
  final bool removalFails;
  final Completer<void>? removal;
  final point = _TestPoint();
  int removalCalls = 0;

  @override
  Future<PointAnnotationManagerPlatformInterface> createPointAnnotationManager({
    String? id,
    String? below,
  }) async => point;

  @override
  Future<void> removeAnnotationManager(
    BaseAnnotationManagerPlatformInterface manager,
  ) async {
    removalCalls++;
    if (removalFails) {
      throw MissingPluginException('annotation#remove_manager');
    }
    await removal?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestPoint implements PointAnnotationManagerPlatformInterface {
  int deleteAllCalls = 0;

  @override
  String get id => '2';

  @override
  Future<PointAnnotation> create(PointAnnotationOptions options) async =>
      PointAnnotation(id: 'point', geometry: options.geometry);

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore_for_file: invalid_use_of_internal_member

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

  group('polyline annotations', () {
    test(
      'addPolyline and replacePolyline filter invalid points in a single pass',
      () async {
        final annotations = _TestAnnotations();
        final controller = AppMapController(
          mapbox.MapboxMap(_TestMap(annotations)),
        );

        final manager = await MapAnnotationService.addPolyline(
          controller,
          const [
            [123.4, 7.8],
            [double.nan, 7.9],
            [123.5, 7.9],
          ],
        );
        expect(annotations.polyline.createdCoordinates, hasLength(2));

        await MapAnnotationService.replacePolyline(manager, const [
          [123.6, 8.0],
          [123.7, 95.0],
          [123.8, 8.1],
        ]);
        expect(annotations.polyline.updatedCoordinates, hasLength(2));

        await expectLater(
          () => MapAnnotationService.addPolyline(controller, const [
            [123.4, 7.8],
            [double.nan, 7.9],
          ]),
          throwsArgumentError,
        );
      },
    );
  });

  group('marker replacement', () {
    test('skips redundant image upload when marker style is unchanged and isolates concurrent maps', () async {
      final annotationsA = _TestAnnotations();
      final annotationsB = _TestAnnotations();
      final controllerA = AppMapController(
        mapbox.MapboxMap(_TestMap(annotationsA)),
      );
      final controllerB = AppMapController(
        mapbox.MapboxMap(_TestMap(annotationsB)),
      );

      final managerA = await MapAnnotationService.addMarker(
        controllerA,
        7.8,
        123.4,
        isOrigin: true,
      );
      final managerB = await MapAnnotationService.addMarker(
        controllerB,
        7.9,
        123.5,
        isOrigin: true,
      );

      await MapAnnotationService.replaceMarker(
        managerA,
        7.81,
        123.41,
        isOrigin: true,
      );
      expect(annotationsA.point.updatedAnnotations, hasLength(1));
      expect(annotationsA.point.updatedAnnotations.single.image, isNull);

      await MapAnnotationService.replaceMarker(
        managerB,
        7.91,
        123.51,
        isOrigin: false,
      );
      expect(annotationsB.point.updatedAnnotations, hasLength(1));
      expect(annotationsB.point.updatedAnnotations.single.image, isNotNull);
    });
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
  final polyline = _TestPolyline();
  int removalCalls = 0;

  @override
  Future<PointAnnotationManagerPlatformInterface> createPointAnnotationManager({
    String? id,
    String? below,
  }) async => point;

  @override
  Future<PolylineAnnotationManagerPlatformInterface>
  createPolylineAnnotationManager({String? id, String? below}) async =>
      polyline;

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

class _TestPolyline implements PolylineAnnotationManagerPlatformInterface {
  List<mapbox.Position>? createdCoordinates;
  List<mapbox.Position>? updatedCoordinates;
  final List<PolylineAnnotation> _annotations = [];

  @override
  String get id => '3';

  @override
  Future<PolylineAnnotation> create(PolylineAnnotationOptions options) async {
    createdCoordinates = options.geometry.coordinates;
    final annotation = PolylineAnnotation(
      id: 'polyline',
      geometry: options.geometry,
    );
    _annotations.add(annotation);
    return annotation;
  }

  @override
  Future<List<PolylineAnnotation>> getAnnotations() async =>
      List<PolylineAnnotation>.from(_annotations);

  @override
  Future<void> update(PolylineAnnotation annotation) async {
    updatedCoordinates = annotation.geometry.coordinates;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestPoint implements PointAnnotationManagerPlatformInterface {
  int deleteAllCalls = 0;
  final List<PointAnnotation> _annotations = [];
  final List<PointAnnotation> updatedAnnotations = [];

  @override
  String get id => '2';

  @override
  Future<PointAnnotation> create(PointAnnotationOptions options) async {
    final annotation = PointAnnotation(id: 'point', geometry: options.geometry);
    _annotations.add(annotation);
    return annotation;
  }

  @override
  Future<List<PointAnnotation>> getAnnotations() async =>
      List<PointAnnotation>.from(_annotations);

  @override
  Future<void> update(PointAnnotation annotation) async {
    updatedAnnotations.add(annotation);
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
    _annotations.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

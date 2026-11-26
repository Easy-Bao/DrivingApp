// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:ui' show Color, VoidCallback;

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart' show EdgeInsets;
import 'package:passenger/src/features/booking/presentation/bloc/live_map/live_map_bloc.dart';

final class _FakeAppMapController extends Fake implements AppMapController {}

final class _FakePointPlatform extends Fake
    implements PointAnnotationManagerPlatformInterface {
  _FakePointPlatform(this._id);

  final String _id;

  @override
  String get id => _id;
}

MapPointAnnotationManager _fakeMarkerManager(String id) =>
    MapPointAnnotationManager(_FakePointPlatform(id));

void main() {
  test(
    'initializes with LiveMapInitial and supports LiveMapReady equality',
    () {
      final bloc = LiveMapBloc();
      expect(bloc.state, const LiveMapInitial());
      expect(
        const LiveMapReady(14.6, 120.9),
        equals(const LiveMapReady(14.6, 120.9)),
      );
      expect(
        const LiveMapReady(14.6, 120.9),
        isNot(equals(const LiveMapReady(14.7, 120.9))),
      );
      return bloc.close();
    },
  );

  test(
    'queues marker, snapshot, and camera fit events until map initialization',
    () async {
      final controller = _FakeAppMapController();
      final addedMarkers = <({double lat, double lng, bool isOrigin})>[];
      final fittedPoints = <List<LatLng>>[];
      final clearedIds = <String>[];
      var counter = 0;

      final bloc = LiveMapBloc(
        addMarker:
            (
              ctrl,
              lat,
              lng, {
              String? label,
              bool isOrigin = false,
              Color? color,
              double? bearing,
              VoidCallback? onTap,
            }) async {
              expect(identical(ctrl, controller), isTrue);
              addedMarkers.add((lat: lat, lng: lng, isOrigin: isOrigin));
              return _fakeMarkerManager('m-${++counter}');
            },
        fitBounds:
            (
              ctrl,
              points, {
              double padding = 80.0,
              EdgeInsets? viewportPadding,
              double? maxZoom,
            }) async {
              expect(identical(ctrl, controller), isTrue);
              expect(maxZoom, 14.5);
              fittedPoints.add(points);
            },
        clearAnnotations: (manager) async {
          if (manager != null) clearedIds.add(manager.id);
        },
      );

      final statesFuture = expectLater(
        bloc.stream,
        emitsInOrder([const LiveMapReady(14.6, 120.9)]),
      );

      bloc
        ..add(const AddMapMarkerEvent(lat: 14.61, lng: 120.91, isOrigin: true))
        ..add(
          const ReplaceMapMarkersEvent(
            markers: [AddMapMarkerEvent(lat: 14.62, lng: 120.92)],
          ),
        )
        ..add(
          const FitMapToCoordinatesEvent(
            coordinates: [LatLng(14.6, 120.9), LatLng(14.62, 120.92)],
            maxZoom: 14.5,
          ),
        )
        ..add(
          InitializeMapEvent(
            controller: controller,
            defaultLat: 14.6,
            defaultLng: 120.9,
          ),
        );

      await statesFuture;
      await Future<void>.delayed(Duration.zero);

      expect(addedMarkers, [
        (lat: 14.61, lng: 120.91, isOrigin: true),
        (lat: 14.62, lng: 120.92, isOrigin: false),
      ]);
      expect(clearedIds, ['m-1']);
      expect(fittedPoints, hasLength(1));
      expect(fittedPoints.single, hasLength(2));

      await bloc.close();
      expect(clearedIds, ['m-1', 'm-2']);
    },
  );

  test('ReplaceMapMarkersEvent clears prior annotations and ClearMapAnnotationsEvent cancels pending work', () async {
    final controller = _FakeAppMapController();
    final clearedIds = <String>[];
    var addedCount = 0;
    var fitCount = 0;

    final bloc = LiveMapBloc(
      addMarker:
          (
            ctrl,
            lat,
            lng, {
            String? label,
            bool isOrigin = false,
            Color? color,
            double? bearing,
            VoidCallback? onTap,
          }) async {
            return _fakeMarkerManager('marker-${++addedCount}');
          },
      fitBounds:
          (
            ctrl,
            points, {
            double padding = 80.0,
            EdgeInsets? viewportPadding,
            double? maxZoom,
          }) async {
            fitCount++;
          },
      clearAnnotations: (manager) async {
        if (manager != null) clearedIds.add(manager.id);
      },
    );

    // Queue before initialization, then clear before InitializeMapEvent.
    bloc
      ..add(const AddMapMarkerEvent(lat: 14.61, lng: 120.91))
      ..add(
        const ReplaceMapMarkersEvent(
          markers: [AddMapMarkerEvent(lat: 14.62, lng: 120.92)],
        ),
      )
      ..add(const FitMapToCoordinatesEvent(coordinates: [LatLng(14.6, 120.9)]))
      ..add(const ClearMapAnnotationsEvent())
      ..add(
        InitializeMapEvent(
          controller: controller,
          defaultLat: 14.6,
          defaultLng: 120.9,
        ),
      );

    await Future<void>.delayed(Duration.zero);
    expect(addedCount, 0);
    expect(fitCount, 0);

    // Now add two markers via ReplaceMapMarkersEvent, then replace again.
    bloc.add(
      const ReplaceMapMarkersEvent(
        markers: [
          AddMapMarkerEvent(lat: 14.63, lng: 120.93),
          AddMapMarkerEvent(lat: 14.64, lng: 120.94),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(addedCount, 2);

    bloc.add(
      const ReplaceMapMarkersEvent(
        markers: [AddMapMarkerEvent(lat: 14.65, lng: 120.95)],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(clearedIds, ['marker-1', 'marker-2']);
    expect(addedCount, 3);

    await bloc.close();
    expect(clearedIds, ['marker-1', 'marker-2', 'marker-3']);
  });

  test('clears orphaned marker manager if invalidated or controller changes mid-flight', () async {
    final controllerA = _FakeAppMapController();
    final controllerB = _FakeAppMapController();
    final pendingAdd = Completer<MapPointAnnotationManager>();
    final orphanedManager = _fakeMarkerManager('orphan');
    final activeManager = _fakeMarkerManager('active');
    final clearedIds = <String>[];

    final bloc = LiveMapBloc(
      addMarker:
          (
            ctrl,
            lat,
            lng, {
            String? label,
            bool isOrigin = false,
            Color? color,
            double? bearing,
            VoidCallback? onTap,
          }) {
            if (identical(ctrl, controllerA)) {
              return pendingAdd.future;
            }
            return Future.value(activeManager);
          },
      clearAnnotations: (manager) async {
        if (manager != null) clearedIds.add(manager.id);
      },
    );

    bloc
      ..add(
        InitializeMapEvent(
          controller: controllerA,
          defaultLat: 14.6,
          defaultLng: 120.9,
        ),
      )
      ..add(const AddMapMarkerEvent(lat: 14.61, lng: 120.91));
    await Future<void>.delayed(Duration.zero);

    // Switch controller while controllerA's addMarker is still in-flight.
    bloc.add(
      InitializeMapEvent(
        controller: controllerB,
        defaultLat: 14.7,
        defaultLng: 121.0,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    pendingAdd.complete(orphanedManager);
    await Future<void>.delayed(Duration.zero);
    expect(clearedIds, ['orphan']);

    // Add a marker on controllerB, then close and confirm cleanup.
    bloc.add(const AddMapMarkerEvent(lat: 14.71, lng: 121.01));
    await Future<void>.delayed(Duration.zero);

    await bloc.close();
    expect(clearedIds, ['orphan', 'active']);
  });
}

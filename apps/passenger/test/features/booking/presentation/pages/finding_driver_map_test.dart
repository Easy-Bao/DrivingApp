import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/location/live_map_bloc.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/nearby_drivers/nearby_drivers_cubit.dart';
import 'package:passenger/src/features/booking/presentation/pages/finding_driver_page.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

class _Booking extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _Nearby extends MockCubit<NearbyDriversState>
    implements NearbyDriversCubit {}

class _Map extends MockBloc<LiveMapEvent, LiveMapState>
    implements LiveMapBloc {}

class _Profiles extends Mock implements DriverProfileRepository {}

final class _MapPlatform extends MapboxMapsFlutterPlatform {
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
  }) => const SizedBox.expand();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'nearby availability adds, moves, and removes driver pins before any booking offer',
    (tester) async {
      registerFallbackValue(const ClearMapAnnotationsEvent());
      MapboxMapsFlutterPlatform.instance = _MapPlatform();
      final booking = _Booking();
      final nearby = _Nearby();
      final map = _Map();
      final updates = StreamController<NearbyDriversState>();
      whenListen(
        nearby,
        updates.stream,
        initialState: const NearbyDriversState(),
      );
      when(() => booking.state).thenReturn(const BookingInitial());
      when(() => booking.stream).thenAnswer((_) => const Stream.empty());
      when(() => booking.hasActiveDriverSearch).thenReturn(false);
      when(() => booking.activeDriverSearch).thenReturn(null);
      final snapshots = <ReplaceMapMarkersEvent>[];
      when(() => map.add(any())).thenAnswer((call) {
        final event = call.positionalArguments.first;
        if (event is ReplaceMapMarkersEvent) snapshots.add(event);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<BookingBloc>.value(value: booking),
              BlocProvider<NearbyDriversCubit>.value(value: nearby),
              BlocProvider<LiveMapBloc>.value(value: map),
            ],
            child: FindingDriverPageContent(
              fare: 30,
              distance: '2 km',
              duration: '5 min',
              destination: const Place(
                id: 'destination',
                name: 'Destination',
                fullAddress: 'Destination',
                latitude: 14.7,
                longitude: 121,
              ),
              pickupLatitude: 14.6,
              pickupLongitude: 120.9,
              profileRepository: _Profiles(),
            ),
          ),
        ),
      );
      await tester.pump();
      Driver driverAt(double latitude) => Driver(
        id: 'nearby',
        name: 'Online driver',
        vehicleType: 'Tricycle',
        plateNumber: 'ABC 123',
        rating: 4.8,
        lat: latitude,
        lng: 120.91,
        distanceKm: 0.3,
        etaMinutes: 2,
        score: 1,
      );
      updates.add(
        NearbyDriversState(drivers: [driverAt(14.61)], hasLoaded: true),
      );
      await tester.pump();
      expect(snapshots, hasLength(1));
      expect(snapshots.last.markers, hasLength(2));
      expect(snapshots.last.markers.first.isOrigin, isTrue);
      expect(snapshots.last.markers.last.lat, 14.61);
      expect(snapshots.last.markers.last.label, 'Online driver');
      updates.add(
        NearbyDriversState(drivers: [driverAt(14.62)], hasLoaded: true),
      );
      await tester.pump();
      expect(snapshots.last.markers.last.lat, 14.62);
      updates.add(const NearbyDriversState(drivers: [], hasLoaded: true));
      await tester.pump();
      expect(snapshots.last.markers, hasLength(1));
      expect(snapshots.last.markers.single.isOrigin, isTrue);
      await tester.pumpWidget(const SizedBox());
      await updates.close();
    },
  );
}

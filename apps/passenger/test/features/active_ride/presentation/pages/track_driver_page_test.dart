import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page.dart';
import 'package:passenger/src/features/chat/chat.dart';

class _Session extends Mock implements SessionStore {}

class _Repository extends Mock implements TrackRepository {}

class _ChatFactory extends Mock implements ChatRepositoryFactory {}

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
    'leaving during chat initialization cannot create a leaked repository',
    (tester) async {
      MapboxMapsFlutterPlatform.instance = _MapPlatform();
      final session = _Session();
      final factory = _ChatFactory();
      final readAt = Completer<DateTime?>();
      when(() => session.readPassengerId()).thenAnswer((_) async => '7');
      when(() => session.readChatReadAt('ride-1'))
          .thenAnswer((_) => readAt.future);
      final lifecycle = AppLifecycleCoordinator();
      final cubit = TrackDriverCubit(
        repository: _Repository(),
        sessionService: session,
        lifecycleCoordinator: lifecycle,
      );
      addTearDown(cubit.close);
      addTearDown(lifecycle.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: TrackDriverPage(
              ride: const RideSnapshot(
                id: 'ride-1',
                status: 'accepted',
                pickupName: 'Pickup',
                dropoffName: 'Dropoff',
                pickupLatitude: 14.6,
                pickupLongitude: 120.9,
              ),
              trackRepository: _Repository(),
              chatRepositoryFactory: factory,
              sessionService: session,
              lifecycleCoordinator: lifecycle,
              onRideTerminated: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      verify(() => session.readChatReadAt('ride-1')).called(1);
      await tester.pumpWidget(const SizedBox());
      readAt.complete(null);
      await tester.pump();
      verifyNever(() => factory.create(currentUserId: '7'));
      expect(tester.takeException(), isNull);
    },
  );
}

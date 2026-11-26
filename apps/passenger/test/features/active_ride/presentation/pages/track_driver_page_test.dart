import 'dart:async';

import 'package:chat/chat.dart';
import 'package:core_domain/core_domain.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';

class _Session extends Mock implements SessionStore {}

class _Repository extends Mock implements TrackRepository {}

class _ChatFactory extends Mock implements ChatRepositoryFactory {}

class _ChatRepository extends Mock implements ChatRepository {}

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

  testWidgets(
    'marks messages received while viewing chat as read after returning',
    (tester) async {
      MapboxMapsFlutterPlatform.instance = _MapPlatform();
      final session = _Session();
      final factory = _ChatFactory();
      final chatRepo = _ChatRepository();
      final messages = <ChatMessage>[];
      DateTime? savedReadAt;

      when(() => session.readPassengerId()).thenAnswer((_) async => '7');
      when(() => session.readChatReadAt('ride-1'))
          .thenAnswer((_) async => savedReadAt);
      when(() => session.saveChatReadAt('ride-1', any()))
          .thenAnswer((invocation) async {
            savedReadAt = invocation.positionalArguments[1] as DateTime;
          });
      when(() => factory.create(currentUserId: '7')).thenReturn(chatRepo);
      when(() => chatRepo.fetchRoomMessages('ride-1'))
          .thenAnswer((_) async => Ok(List<ChatMessage>.of(messages)));
      when(() => chatRepo.dispose()).thenAnswer((_) async {});

      final lifecycle = AppLifecycleCoordinator();
      final cubit = TrackDriverCubit(
        repository: _Repository(),
        sessionService: session,
        lifecycleCoordinator: lifecycle,
      );
      addTearDown(cubit.close);
      addTearDown(lifecycle.dispose);

      final router = GoRouter(
        initialLocation: '/track',
        routes: [
          GoRoute(
            path: '/track',
            builder: (_, _) => BlocProvider.value(
              value: cubit,
              child: TrackDriverPage(
                ride: const RideSnapshot(
                  id: 'ride-1',
                  status: 'accepted',
                  pickupName: 'Pickup',
                  dropoffName: 'Dropoff',
                  pickupLatitude: 14.6,
                  pickupLongitude: 120.9,
                  driverId: 'driver-1',
                  driverName: 'Alex',
                ),
                trackRepository: _Repository(),
                chatRepositoryFactory: factory,
                sessionService: session,
                lifecycleCoordinator: lifecycle,
                onRideTerminated: () {},
              ),
            ),
          ),
          GoRoute(
            path: '/chat',
            name: ChatRoutes.driverChat,
            builder: (context, _) {
              if (messages.isEmpty) {
                messages.add(
                  ChatMessage(
                    id: 'msg-1',
                    senderId: 'driver-1',
                    text: 'Arriving now',
                    isFromPeer: true,
                    createdAt: DateTime.now().toUtc().add(
                      const Duration(seconds: 5),
                    ),
                  ),
                );
              }
              return Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back from chat'),
                ),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip('Message driver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Back from chat'), findsOneWidget);

      await tester.tap(find.text('Back from chat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(savedReadAt, isNotNull);
      expect(savedReadAt!.isBefore(messages.single.createdAt), isFalse);
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isFalse);
    },
  );
}

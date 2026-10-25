import 'dart:convert';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/chat/chat.dart';
import 'package:driver/src/features/chat/domain/entities/chat_peer.dart';
import 'package:driver/src/features/chat/presentation/view/driver_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements ChatRepository {}

class MockFactory extends Mock implements ChatRepositoryFactory {}

void main() {
  testWidgets('camera and photo file actions open the matching image source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:8080');
    addTearDown(dotenv.clean);
    registerFallbackValue(Uint8List(0));
    final repository = MockRepository();
    final factory = MockFactory();
    when(() => factory.create(currentUserId: '7')).thenReturn(repository);
    when(() => repository.fetchPeer('ride-1'))
        .thenAnswer((_) async => const Err(NetworkFailure('Unavailable')));
    when(() => repository.initializeChatRoom(roomId: 'ride-1'))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.connectionStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.chatEventsStream)
        .thenAnswer((_) => const Stream.empty());
    when(
      () => repository.establishChatConnection(
        roomId: 'ride-1',
        chatUri: Uri.parse('ws://localhost:8080/api/v1/chat/ws?roomId=ride-1'),
        token: null,
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(() => repository.fetchRoomMessages('ride-1'))
        .thenAnswer((_) async => const Ok([]));
    when(() => repository.terminateChatConnection())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.dispose()).thenAnswer((_) async {});
    final sources = <int>[];
    const channel = MethodChannel('plugins.flutter.io/image_picker');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'pickImage') {
        sources.add((call.arguments as Map)['source'] as int);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: ChatPage(
          roomId: 'ride-1',
          userId: '7',
          chatRepositoryFactory: factory,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Take photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Attach photo file'));
    await tester.pumpAndSettle();
    expect(sources, [0, 1]);
    verifyNever(() => repository.sendImage(any(), any()));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  for (final scenario in [
    'allowed',
    'denied',
    'missing phone',
    'expired',
    'dialer unavailable',
    'lookup failed',
  ]) {
    testWidgets('chat call action: $scenario', (tester) async {
      final repository = MockRepository();
      final factory = MockFactory();
      var lookups = 0;
      var launches = 0;
      String? launchedUrl;
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'launch') {
          launches++;
          launchedUrl = (call.arguments as Map)['url'] as String;
          return scenario != 'dialer unavailable';
        }
        return false;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      when(() => factory.create(currentUserId: '7')).thenReturn(repository);
      when(() => repository.fetchPeer('ride-1')).thenAnswer((_) async {
        lookups++;
        if (scenario == 'lookup failed' && lookups > 1) {
          return const Err(NetworkFailure('Unable to load trip contact.'));
        }
        return Ok(
          ChatPeer(
            name: 'Alex',
            phone: scenario == 'missing phone' ? '' : '+639000000000',
            contactAllowed:
                scenario != 'denied' && !(scenario == 'expired' && lookups > 1),
          ),
        );
      });
      when(() => repository.initializeChatRoom(roomId: 'ride-1')).thenAnswer(
        (_) async => const Err(NetworkFailure('Unable to connect.')),
      );
      when(() => repository.terminateChatConnection())
          .thenAnswer((_) async => const Ok(null));
      when(() => repository.dispose()).thenAnswer((_) async {});
      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            roomId: 'ride-1',
            userId: '7',
            chatRepositoryFactory: factory,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byTooltip('Call passenger');
      if (scenario == 'denied' || scenario == 'missing phone') {
        expect(action, findsNothing);
        expect(lookups, 1);
      } else {
        expect(
          find.ancestor(of: action, matching: find.byType(AppBar)),
          findsOneWidget,
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(lookups, 2);
        expect(
          launches,
          scenario == 'expired' || scenario == 'lookup failed' ? 0 : 1,
        );
        if (launches > 0) expect(launchedUrl, 'tel:+639000000000');
        if (scenario == 'expired') {
          expect(action, findsNothing);
          expect(
            find.text('Calling is no longer available for this trip.'),
            findsOneWidget,
          );
        }
        if (scenario == 'lookup failed') {
          expect(find.text('Unable to load trip contact.'), findsOneWidget);
        }
        if (scenario == 'dialer unavailable') {
          expect(
            find.text('Unable to open the phone dialer. Please try again.'),
            findsOneWidget,
          );
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  for (final accessDenied in [true, false]) {
    testWidgets(
      accessDenied
          ? 'shows the centered empty conversation label without a retry button'
          : 'keeps connection errors and retry available',
      (tester) async {
        final repository = MockRepository();
        final factory = MockFactory();
        when(() => factory.create(currentUserId: '7')).thenReturn(repository);
        when(() => repository.fetchPeer('ride-1'))
            .thenAnswer((_) async => const Err(NetworkFailure('Unavailable')));
        when(() => repository.initializeChatRoom(roomId: 'ride-1')).thenAnswer(
          (_) async => accessDenied
              ? const Err(
                  ServerFailure.withStatusCode(
                    "You don't have permission to do that.",
                    403,
                  ),
                )
              : const Err(NetworkFailure('Unable to connect.')),
        );
        when(() => repository.terminateChatConnection())
            .thenAnswer((_) async => const Ok(null));
        when(() => repository.dispose()).thenAnswer((_) async {});
        await tester.pumpWidget(
          MaterialApp(
            home: ChatPage(
              roomId: 'ride-1',
              userId: '7',
              chatRepositoryFactory: factory,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text("You don't have permission to do that."),
          findsNothing,
        );
        expect(
          find.text('Try again'),
          accessDenied ? findsNothing : findsOneWidget,
        );
        expect(
          find.text(
            "Couldn't connect. Check your internet connection and try again.",
          ),
          accessDenied ? findsNothing : findsOneWidget,
        );
        final emptyLabel = find.text('No message yet');
        expect(emptyLabel, accessDenied ? findsOneWidget : findsNothing);
        if (accessDenied) {
          final center = find
              .ancestor(of: emptyLabel, matching: find.byType(Center))
              .first;
          expect(tester.getCenter(emptyLabel), tester.getCenter(center));
        }
        verifyNever(() => repository.fetchRoomMessages(any()));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('closed history shows pictures, driver details, and ended flag', (
    tester,
  ) async {
    final repository = MockRepository();
    final factory = MockFactory();
    final picture = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      ),
    );
    when(() => factory.create(currentUserId: '7')).thenReturn(repository);
    when(() => repository.initializeChatRoom(roomId: 'ride-1'))
        .thenAnswer((_) async => const Err(ChatRoomLockedFailure()));
    when(() => repository.fetchPeer('ride-1')).thenAnswer(
      (_) async => const Ok(
        ChatPeer(name: 'Alex Driver', plate: 'ABC 123', vehicle: 'Motorcycle'),
      ),
    );
    when(() => repository.fetchRoomMessages('ride-1')).thenAnswer(
      (_) async => Ok([
        ChatMessage(
          id: 'text',
          text: 'Previous conversation',
          senderId: '8',
          isFromPeer: true,
          createdAt: DateTime.utc(2026),
        ),
        ChatMessage(
          id: 'picture',
          text: '',
          imageKey: 'private-picture',
          senderId: '8',
          isFromPeer: true,
          createdAt: DateTime.utc(2026, 1, 1, 0, 1),
        ),
      ]),
    );
    when(() => repository.fetchImage('ride-1', 'picture'))
        .thenAnswer((_) async => Ok(picture));
    when(() => repository.markRead('ride-1', 'picture'))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.terminateChatConnection())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.dispose()).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          roomId: 'ride-1',
          userId: '7',
          chatRepositoryFactory: factory,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Previous conversation'), findsOneWidget);
    expect(find.text('No message yet'), findsNothing);
    expect(find.text('This conversation has ended'), findsOneWidget);
    expect(find.text('Alex Driver'), findsOneWidget);
    expect(find.text('ABC 123 | Motorcycle'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    final pictureFrame = tester.widget<Container>(
      find
          .ancestor(
            of: find.byType(ChatPicture),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(pictureFrame.padding, EdgeInsets.zero);
    expect(pictureFrame.decoration, isNull);

    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Take photo'), findsNothing);
    expect(find.byTooltip('Attach photo file'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

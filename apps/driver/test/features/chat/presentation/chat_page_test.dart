import 'dart:convert';
import 'dart:typed_data';

import 'package:driver/src/features/chat/chat.dart';
import 'package:driver/src/features/chat/domain/entities/chat_peer.dart';
import 'package:driver/src/features/chat/presentation/view/driver_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements ChatRepository {}

class MockFactory extends Mock implements ChatRepositoryFactory {}

void main() {
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
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Send picture'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

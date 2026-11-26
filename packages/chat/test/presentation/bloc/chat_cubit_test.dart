import 'dart:async';

import 'package:chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  setUpAll(() => registerFallbackValue(Uri.parse('wss://example.test')));

  test(
    'two checks require a peer receipt and never regress on stale history',
    () async {
      final repository = MockChatRepository();
      final events = StreamController<Result<ChatEvent, Failure>>();
      when(() => repository.connectionStateStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => repository.chatEventsStream).thenAnswer((_) => events.stream);
      when(
        () => repository.establishChatConnection(
          roomId: 'ride-1',
          chatUri: any(named: 'chatUri'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      final outgoing = ChatMessage(
        id: 'sent',
        text: 'Hello',
        senderId: '7',
        isFromPeer: false,
        createdAt: DateTime.utc(2026),
      );
      when(() => repository.fetchRoomMessages('ride-1'))
          .thenAnswer((_) async => Ok([outgoing]));
      when(() => repository.terminateChatConnection())
          .thenAnswer((_) async => const Ok(null));
      when(() => repository.dispose()).thenAnswer((_) async {});
      final cubit = ChatCubit(chatRepository: repository, currentUserId: '7');
      await cubit.connectToChatRoom(
        roomId: 'ride-1',
        chatUri: Uri.parse('wss://example.test/chat'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.messages.single.deliveryStatus,
        ChatMessageDeliveryStatus.sent,
      );
      events.add(
        Ok(ChatMessagesRead(senderId: '7', through: DateTime.utc(2026))),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.messages.single.deliveryStatus,
        ChatMessageDeliveryStatus.sent,
      );
      events.add(
        Ok(ChatMessagesRead(senderId: '8', through: DateTime.utc(2026))),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.messages.single.deliveryStatus,
        ChatMessageDeliveryStatus.seen,
      );
      events.add(Ok(ChatHistoryReceived([outgoing])));
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.messages.single.deliveryStatus,
        ChatMessageDeliveryStatus.seen,
      );
      await cubit.close();
      await events.close();
    },
  );

  test('does not send a message while the connection is offline', () async {
    final repository = MockChatRepository();
    when(() => repository.sendChatMessage('I have arrived'))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.terminateChatConnection())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.dispose()).thenAnswer((_) async {});

    final cubit = ChatCubit(chatRepository: repository, currentUserId: '7');

    expect(await cubit.sendMessage('I have arrived'), isFalse);
    expect(cubit.state.messages, isEmpty);
    verifyNever(() => repository.sendChatMessage(any()));

    await cubit.close();
  });

  test('retries a failed outgoing message in place', () async {
    final repository = MockChatRepository();
    var attempts = 0;
    when(() => repository.connectionStateStream)
        .thenAnswer((_) => const Stream<ChatConnectionState>.empty());
    when(
      () => repository.establishChatConnection(
        roomId: 'ride-1',
        chatUri: any(named: 'chatUri'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(() => repository.chatEventsStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.fetchRoomMessages('ride-1'))
        .thenAnswer((_) async => const Ok(<ChatMessage>[]));
    when(() => repository.sendChatMessage('I have arrived'))
        .thenAnswer((_) async {
          attempts++;
          return attempts == 1
              ? const Err(NetworkFailure('Send failed'))
              : const Ok(null);
        });
    when(() => repository.terminateChatConnection())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.dispose()).thenAnswer((_) async {});

    final cubit = ChatCubit(chatRepository: repository, currentUserId: '7');
    await cubit.connectToChatRoom(
      roomId: 'ride-1',
      chatUri: Uri.parse('wss://example.test/chat/ride-1'),
    );

    expect(await cubit.sendMessage('I have arrived'), isFalse);
    expect(
      cubit.state.messages.single.deliveryStatus,
      ChatMessageDeliveryStatus.failed,
    );

    expect(await cubit.retryMessage(cubit.state.messages.single), isTrue);
    expect(
      cubit.state.messages.single.deliveryStatus,
      ChatMessageDeliveryStatus.sending,
    );
    expect(attempts, 2);

    await cubit.close();
  });

  test('loads previous messages when conversation has ended', () async {
    final repository = MockChatRepository();
    when(() => repository.connectionStateStream)
        .thenAnswer((_) => const Stream<ChatConnectionState>.empty());
    when(() => repository.terminateChatConnection())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.dispose()).thenAnswer((_) async {});
    when(() => repository.fetchPeer('ride-1'))
        .thenAnswer((_) async => const Err(ServerFailure('unavailable')));
    final previousMessage = ChatMessage(
      id: 'old-message',
      text: 'Previous conversation',
      senderId: '8',
      isFromPeer: true,
      createdAt: DateTime.utc(2026),
    );
    when(() => repository.fetchRoomMessages('ride-1'))
        .thenAnswer((_) async => Ok([previousMessage]));
    when(() => repository.initializeChatRoom(roomId: 'ride-1'))
        .thenAnswer((_) async => const Err(ChatRoomLockedFailure()));

    final cubit = ChatCubit(chatRepository: repository);

    final initialized = await cubit.initializeChatRoom(roomId: 'ride-1');

    expect(initialized, isFalse);
    expect(cubit.state.isRoomLocked, isTrue);
    expect(cubit.state.isConnected, isFalse);
    expect(cubit.state.messages, [previousMessage]);
    expect(cubit.state.lockReasonMessage, 'Chat is closed for this trip.');
    expect(cubit.state.errorMessage, isNull);

    await cubit.close();
  });

  test(
    'redacts a realtime lock reason before it reaches presentation state',
    () async {
      final repository = MockChatRepository();
      when(() => repository.connectionStateStream)
          .thenAnswer((_) => const Stream<ChatConnectionState>.empty());
      when(
        () => repository.establishChatConnection(
          roomId: 'ride-1',
          chatUri: Uri.parse('wss://example.test/chat/ride-1'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(() => repository.chatEventsStream).thenAnswer(
        (_) => Stream.value(
          const Ok<ChatEvent, Failure>(
            ChatRoomLocked('pq: relation chat_rooms is missing'),
          ),
        ),
      );
      when(() => repository.fetchRoomMessages('ride-1'))
          .thenAnswer((_) async => const Ok(<ChatMessage>[]));
      when(() => repository.terminateChatConnection())
          .thenAnswer((_) async => const Ok(null));
      when(() => repository.dispose()).thenAnswer((_) async {});

      final cubit = ChatCubit(chatRepository: repository);

      await cubit.connectToChatRoom(
        roomId: 'ride-1',
        chatUri: Uri.parse('wss://example.test/chat/ride-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isRoomLocked, isTrue);
      expect(cubit.state.lockReasonMessage, 'Chat is closed for this trip.');
      expect(cubit.state.lockReasonMessage, isNot(contains('pq')));
      verify(() => repository.terminateChatConnection()).called(1);

      await cubit.close();
    },
  );
}

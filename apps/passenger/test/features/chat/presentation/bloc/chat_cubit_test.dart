import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/chat/presentation/bloc/chat_cubit.dart';

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

  test('sends a message only after the connection is established', () async {
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
    when(() => repository.chatEventsStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.fetchRoomMessages('ride-1'))
        .thenAnswer((_) async => const Ok(<ChatMessage>[]));
    when(() => repository.sendChatMessage('I have arrived'))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.terminateChatConnection())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.dispose()).thenAnswer((_) async {});

    final cubit = ChatCubit(chatRepository: repository, currentUserId: '7');
    await cubit.connectToChatRoom(
      roomId: 'ride-1',
      wsUri: Uri.parse('wss://example.test/chat/ride-1'),
    );

    expect(cubit.state.isConnected, isTrue);
    expect(await cubit.sendMessage('I have arrived'), isTrue);
    expect(cubit.state.messages.single.text, 'I have arrived');
    expect(
      cubit.state.messages.single.deliveryStatus,
      ChatMessageDeliveryStatus.sending,
    );

    await cubit.close();
  });

  test('loads previous messages when conversation has ended', () async {
    final repository = MockChatRepository();
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
        wsUri: Uri.parse('wss://example.test/chat/ride-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isRoomLocked, isTrue);
      expect(cubit.state.lockReasonMessage, 'Chat is closed for this trip.');
      expect(cubit.state.lockReasonMessage, isNot(contains('pq')));
      verify(() => repository.terminateChatConnection()).called(1);

      await cubit.close();
    },
  );

  test('tracks peer typing and clears it when the peer stops', () async {
    final repository = MockChatRepository();
    final events = StreamController<Result<ChatEvent, Failure>>();
    final connectionStates = StreamController<ChatConnectionState>.broadcast();
    when(() => repository.connectionStateStream)
        .thenAnswer((_) => connectionStates.stream);
    when(
      () => repository.establishChatConnection(
        roomId: 'ride-1',
        chatUri: Uri.parse('wss://example.test/chat/ride-1'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(() => repository.chatEventsStream).thenAnswer((_) => events.stream);
    when(() => repository.fetchRoomMessages('ride-1'))
        .thenAnswer((_) async => const Ok(<ChatMessage>[]));
    when(() => repository.terminateChatConnection())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.dispose()).thenAnswer((_) async {});

    final cubit = ChatCubit(chatRepository: repository);

    await cubit.connectToChatRoom(
      roomId: 'ride-1',
      wsUri: Uri.parse('wss://example.test/chat/ride-1'),
    );
    connectionStates.add(const ChatConnected());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isConnected, isTrue);

    final message = ChatMessage(
      id: 'message-1',
      text: 'I am here',
      senderId: '8',
      isFromPeer: true,
      createdAt: DateTime.utc(2026, 8, 27, 10),
    );
    events.add(Ok<ChatEvent, Failure>(ChatMessageReceived(message)));
    await Future<void>.delayed(Duration.zero);
    connectionStates.add(
      const ChatDisconnected(reconnectIn: Duration(seconds: 1)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isConnected, isFalse);
    expect(cubit.state.messages, contains(message));
    expect(
      cubit.state.errorMessage,
      'Connection lost. Reconnecting automatically...',
    );
    connectionStates.add(const ChatConnected());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isConnected, isTrue);
    expect(cubit.state.messages, contains(message));
    events.add(
      const Ok<ChatEvent, Failure>(
        ChatTypingChanged(isTyping: true, isFromPeer: true),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isPeerTyping, isTrue);

    events.add(
      const Ok<ChatEvent, Failure>(
        ChatTypingChanged(isTyping: false, isFromPeer: true),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isPeerTyping, isFalse);

    await cubit.close();
    await events.close();
    await connectionStates.close();
  });
}

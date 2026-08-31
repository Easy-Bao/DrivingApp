import 'package:chat/chat.dart';
import 'dart:async';

import 'package:driver_app/src/features/chat/presentation/bloc/chat/chat_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  test(
    'shows a resolved state when room initialization returns resolved',
    () async {
      final repository = MockChatRepository();
      when(
        () => repository.connectionStateStream,
      ).thenAnswer((_) => const Stream<ChatConnectionState>.empty());
      when(
        () => repository.terminateChatConnection(),
      ).thenAnswer((_) async => const Right(null));
      when(() => repository.dispose()).thenAnswer((_) async {});
      when(
        () => repository.initializeChatRoom(roomId: 'ride-1'),
      ).thenAnswer((_) async => const Left(ChatRoomLockedFailure()));

      final cubit = ChatCubit(chatRepository: repository);

      final initialized = await cubit.initializeChatRoom(roomId: 'ride-1');

      expect(initialized, isFalse);
      expect(cubit.state.isRoomLocked, isTrue);
      expect(cubit.state.isConnected, isFalse);
      expect(
        cubit.state.lockReasonMessage,
        'This chat has already been resolved.',
      );
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    },
  );

  test(
    'redacts a realtime lock reason before it reaches presentation state',
    () async {
      final repository = MockChatRepository();
      when(
        () => repository.connectionStateStream,
      ).thenAnswer((_) => const Stream<ChatConnectionState>.empty());
      when(
        () => repository.establishChatConnection(
          roomId: 'ride-1',
          chatUri: Uri.parse('wss://example.test/chat/ride-1'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const Right(null));
      when(() => repository.chatEventsStream).thenAnswer(
        (_) => Stream.value(
          const Right<Failure, ChatEvent>(
            ChatRoomLocked('pq: relation chat_rooms is missing'),
          ),
        ),
      );
      when(
        () => repository.fetchRoomMessages('ride-1'),
      ).thenAnswer((_) async => const Right(<ChatMessage>[]));
      when(
        () => repository.terminateChatConnection(),
      ).thenAnswer((_) async => const Right(null));
      when(() => repository.dispose()).thenAnswer((_) async {});

      final cubit = ChatCubit(chatRepository: repository);

      await cubit.connectToChatRoom(
        roomId: 'ride-1',
        wsUri: Uri.parse('wss://example.test/chat/ride-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isRoomLocked, isTrue);
      expect(
        cubit.state.lockReasonMessage,
        'This chat has already been resolved.',
      );
      expect(cubit.state.lockReasonMessage, isNot(contains('pq')));

      await cubit.close();
    },
  );

  test('tracks peer typing and clears it when the peer stops', () async {
    final repository = MockChatRepository();
    final events = StreamController<Either<Failure, ChatEvent>>();
    final connectionStates = StreamController<ChatConnectionState>.broadcast();
    when(
      () => repository.connectionStateStream,
    ).thenAnswer((_) => connectionStates.stream);
    when(
      () => repository.establishChatConnection(
        roomId: 'ride-1',
        chatUri: Uri.parse('wss://example.test/chat/ride-1'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(() => repository.chatEventsStream).thenAnswer((_) => events.stream);
    when(
      () => repository.fetchRoomMessages('ride-1'),
    ).thenAnswer((_) async => const Right(<ChatMessage>[]));
    when(
      () => repository.terminateChatConnection(),
    ).thenAnswer((_) async => const Right(null));
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
      senderId: '7',
      isFromPeer: true,
      createdAt: DateTime.utc(2026, 8, 27, 10),
    );
    events.add(Right<Failure, ChatEvent>(ChatMessageReceived(message)));
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
      const Right<Failure, ChatEvent>(
        ChatTypingChanged(isTyping: true, isFromPeer: true),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isPeerTyping, isTrue);

    events.add(
      const Right<Failure, ChatEvent>(
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

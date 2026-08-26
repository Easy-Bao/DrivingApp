import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/chat/bloc/chat/chat_cubit.dart';
import 'package:shared_core/shared_core.dart';

class MockChatRepository extends Mock implements IChatRepository {}

void main() {
  test('shows a resolved state when the room is already locked', () async {
    final repository = MockChatRepository();
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
  });

  test(
    'redacts a realtime lock reason before it reaches presentation state',
    () async {
      final repository = MockChatRepository();
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
  });
}

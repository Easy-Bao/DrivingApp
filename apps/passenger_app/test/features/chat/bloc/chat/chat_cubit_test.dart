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
      () => repository.initializeChatRoom(
        roomId: 'ride-1',
        passengerId: 'passenger-1',
        driverId: 'driver-1',
      ),
    ).thenAnswer((_) async => const Left(ChatRoomLockedFailure()));

    final cubit = ChatCubit(chatRepository: repository);

    final initialized = await cubit.initializeChatRoom(
      roomId: 'ride-1',
      passengerId: 'passenger-1',
      driverId: 'driver-1',
    );

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
}

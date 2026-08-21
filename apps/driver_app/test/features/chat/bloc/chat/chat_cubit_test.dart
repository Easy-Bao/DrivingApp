import 'package:driver_app/src/features/chat/bloc/chat/chat_cubit.dart';
import 'package:driver_app/src/features/chat/data/datasources/chat_room_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';

class MockChatRepository extends Mock implements IChatRepository {}

class MockChatRoomRemoteDataSource extends Mock
    implements ChatRoomRemoteDataSource {}

void main() {
  test(
    'shows a resolved state when room initialization returns resolved',
    () async {
      final repository = MockChatRepository();
      final roomDataSource = MockChatRoomRemoteDataSource();
      when(
        () => repository.terminateChatConnection(),
      ).thenAnswer((_) async => const Right(null));
      when(() => repository.dispose()).thenAnswer((_) async {});
      when(
        () => roomDataSource.initializeRoom(
          roomId: 'ride-1',
          driverId: 'driver-1',
          passengerId: 'passenger-1',
        ),
      ).thenAnswer((_) async => ChatRoomInitializationStatus.resolved);

      final cubit = ChatCubit(
        chatRepository: repository,
        roomRemoteDataSource: roomDataSource,
      );

      final initialized = await cubit.initializeChatRoom(
        roomId: 'ride-1',
        driverId: 'driver-1',
        passengerId: 'passenger-1',
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
    },
  );
}

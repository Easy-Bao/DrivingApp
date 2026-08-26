import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IChatRepository {
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
    String? token,
  });

  Future<Either<Failure, void>> terminateChatConnection();

  Future<Either<Failure, void>> initializeChatRoom({required String roomId});

  Future<Either<Failure, void>> sendChatMessage(String text);

  Future<Either<Failure, void>> sendTypingStatus(bool isTyping);

  Future<Either<Failure, List<ChatMessage>>> fetchRoomMessages(String roomId);

  Future<Either<Failure, void>> resolveChatRoom(String roomId);

  Future<void> dispose();

  Stream<Either<Failure, ChatEvent>> get chatEventsStream;

  Stream<ChatConnectionState> get connectionStateStream;

  bool get isSessionConnected;
}

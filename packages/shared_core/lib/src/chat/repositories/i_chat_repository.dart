import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IChatRepository {
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
    String? token,
  });

  Future<Either<Failure, void>> terminateChatConnection();

  Future<Either<Failure, void>> sendChatMessage(String text);

  Future<Either<Failure, List<ChatMessage>>> fetchRoomMessages(String roomId);

  Stream<Either<Failure, ChatEvent>> get chatEventsStream;

  bool get isSessionConnected;
}

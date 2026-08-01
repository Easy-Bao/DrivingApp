import 'package:chat_service/src/models/chat_event.dart';
import 'package:chat_service/src/models/chat_message.dart';
import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class IChatRepository {
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
  });

  Future<Either<Failure, void>> terminateChatConnection();

  Future<Either<Failure, void>> sendChatMessage(String text);

  Future<Either<Failure, List<ChatMessage>>> fetchRoomMessages(String roomId);

  Stream<Either<Failure, ChatEvent>> get chatEventsStream;

  bool get isSessionConnected;
}

import 'package:chat_service/src/features/chat/domain/entities/chat_event.dart';
import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class ChatRepository {
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

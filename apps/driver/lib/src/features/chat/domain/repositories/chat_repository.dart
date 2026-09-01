import 'package:driver/src/features/chat/domain/entities/chat_connection_state.dart';
import 'package:driver/src/features/chat/domain/entities/chat_event.dart';
import 'package:driver/src/features/chat/domain/entities/chat_message.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ChatRepository {
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

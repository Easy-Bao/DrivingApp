import 'package:chat_service/src/features/chat/domain/entities/chat_event.dart';
import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

/// Repository interface governing the chat room lifecycle, message actions, and event streams.
abstract class ChatRepository {
  /// Establishes the real-time session connection with the target chat room.
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
  });

  /// Disconnects from the current chat session and performs cleanups.
  Future<Either<Failure, void>> terminateChatConnection();

  /// Sends a message string to the chat room.
  Future<Either<Failure, void>> sendChatMessage(String text);

  /// A stream of parsed real-time events containing messages and room lock alerts.
  Stream<Either<Failure, ChatEvent>> get chatEventsStream;

  /// Returns whether the database/socket session is currently active.
  bool get isSessionConnected;
}

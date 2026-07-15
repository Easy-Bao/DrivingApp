import 'package:chat_service/src/features/chat/domain/entities/chat_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

/// Data model representing chat messages returned from or sent to API endpoints.
@freezed
abstract class ChatMessageModel with _$ChatMessageModel {
  /// Constructor defining serialized chat message properties.
  const factory ChatMessageModel({
    required String text,
    required String senderId,
    required DateTime createdAt,
  }) = _ChatMessageModel;

  /// Creates a [ChatMessageModel] from JSON map.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  const ChatMessageModel._();

  /// Converts this serialized data model into a pure Dart [ChatMessage] domain entity.
  ChatMessage toEntity({required String currentUserId}) {
    return ChatMessage(
      text: text,
      senderId: senderId,
      isFromPeer: senderId != currentUserId,
      createdAt: createdAt.toLocal(),
    );
  }
}

import 'package:chat_service/src/features/chat/domain/entities/chat_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/chat_message_model.freezed.dart';
part 'generated/chat_message_model.g.dart';

@freezed
abstract class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String text,
    required String senderId,
    required DateTime createdAt,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  const ChatMessageModel._();

  ChatMessage toEntity({required String currentUserId}) {
    return ChatMessage(
      text: text,
      senderId: senderId,
      isFromPeer: senderId != currentUserId,
      createdAt: createdAt.toLocal(),
    );
  }
}

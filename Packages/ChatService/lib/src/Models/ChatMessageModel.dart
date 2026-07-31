import 'package:chat_service/src/Models/ChatMessage.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/ChatMessageModel.g.dart';


@JsonSerializable()
class ChatMessageModel extends Equatable {
  final String text;
  final String senderId;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.text,
    required this.senderId,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  ChatMessage toEntity({required String currentUserId}) {
    return ChatMessage(
      text: text,
      senderId: senderId,
      isFromPeer: senderId != currentUserId,
      createdAt: createdAt.toLocal(),
    );
  }

  @override
  List<Object?> get props => [text, senderId, createdAt];
}


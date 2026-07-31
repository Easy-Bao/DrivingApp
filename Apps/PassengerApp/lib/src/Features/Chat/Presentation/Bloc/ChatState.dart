import 'package:chat_service/chat_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/chat_state.freezed.dart';

@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isConnecting,
    @Default(false) bool isConnected,
    @Default(false) bool isRoomLocked,
    @Default('This chat room has been resolved.') String lockReasonMessage,
    String? errorMessage,
  }) = _ChatState;
}

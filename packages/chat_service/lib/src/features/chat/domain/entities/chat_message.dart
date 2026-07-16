/// A domain entity representing a single chat message exchanged between passenger and driver.
class ChatMessage {
  /// The textual content of the message.
  final String text;

  /// The unique identifier of the user who sent the message.
  final String senderId;

  /// Indicates whether the message originated from the conversation peer.
  final bool isFromPeer;

  /// The timestamp indicating when the message was sent.
  final DateTime createdAt;

  /// Creates a [ChatMessage] domain entity.
  const ChatMessage({
    required this.text,
    required this.senderId,
    required this.isFromPeer,
    required this.createdAt,
  });
}

class ChatMessage {
  final String text;
  final String senderId;
  final bool isFromPeer;
  final DateTime createdAt;

  const ChatMessage({
    required this.text,
    required this.senderId,
    required this.isFromPeer,
    required this.createdAt,
  });
}

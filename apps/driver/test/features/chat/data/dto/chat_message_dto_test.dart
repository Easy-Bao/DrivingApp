import 'package:driver/src/features/chat/data/dto/chat_message_dto.dart';
import 'package:driver/src/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('destructures canonical and legacy chat fields', () {
    final message = ChatMessageDto.fromJson(const {
      'message_id': 303,
      'message': 'Passenger is ready',
      'sender_id': 42,
      'created_at': '2026-09-04T08:00:00Z',
      'delivery_status': 'sent',
    });

    expect(message.id, startsWith('legacy:42:'));
    expect(message.text, 'Passenger is ready');
    expect(message.senderId, '42');
    expect(message.createdAt, DateTime.utc(2026, 9, 4, 8));
    expect(message.deliveryStatus, ChatMessageDeliveryStatus.sent);
  });

  test('rejects non-string message fields at the transport boundary', () {
    expect(
      () => ChatMessageDto.fromJson(const {'text': 42}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => ChatMessageDto.fromJson(const {'createdAt': 42}),
      throwsA(isA<FormatException>()),
    );
  });
}

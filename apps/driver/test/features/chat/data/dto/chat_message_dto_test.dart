import 'package:driver/src/features/chat/data/dto/chat_message_dto.dart';
import 'package:driver/src/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('server echo is sent and only an explicit receipt is seen', () {
    final payload = <String, dynamic>{
      'id': 'picture-1',
      'text': '',
      'sender_id': '7',
      'created_at': '2026-10-23T00:00:00Z',
      'image_key': 'private-picture',
    };
    final sent = ChatMessageDto.fromJson(payload).toEntity(currentUserId: '7');
    expect(sent.deliveryStatus, ChatMessageDeliveryStatus.sent);
    expect(sent.hasImage, isTrue);
    final seen = ChatMessageDto.fromJson({...payload, 'seen': true})
        .toEntity(currentUserId: '7');
    expect(seen.deliveryStatus, ChatMessageDeliveryStatus.seen);
  });

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

import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_counterparty.dart';

void main() {
  test('destructures an authenticated counterparty payload', () {
    final counterparty = RideCounterparty.fromJson(const {
      'userId': 42,
      'name': 'Nearby Driver',
      'phone': ' +639000000000 ',
      'contact_allowed': true,
    });

    expect(counterparty.userId, '42');
    expect(counterparty.name, 'Nearby Driver');
    expect(counterparty.phone, '+639000000000');
    expect(counterparty.contactAllowed, isTrue);
  });

  test('keeps contact permission false for non-boolean payload values', () {
    final counterparty = RideCounterparty.fromJson(const {
      'user_id': '42',
      'name': null,
      'phone': null,
      'contact_allowed': 'true',
    });

    expect(counterparty.userId, '42');
    expect(counterparty.name, isEmpty);
    expect(counterparty.phone, isEmpty);
    expect(counterparty.contactAllowed, isFalse);
  });
}

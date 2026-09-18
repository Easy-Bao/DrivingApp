import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger/src/infrastructure/session/passenger_storage_keys.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late PassengerSessionStore sessionStore;

  setUp(() {
    storage = MockFlutterSecureStorage();
    sessionStore = PassengerSessionStore(storage: storage);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  test('clears only passenger-owned session keys', () async {
    await sessionStore.clearSession();

    for (final key in const [
      PassengerStorageKeys.jwtToken,
      PassengerStorageKeys.refreshToken,
      PassengerStorageKeys.driverId,
      PassengerStorageKeys.passengerId,
      PassengerStorageKeys.activeRideId,
    ]) {
      verify(() => storage.delete(key: key)).called(1);
    }
    verifyNever(() => storage.deleteAll());
  });

  test('keeps granular token deletion behavior', () async {
    await sessionStore.deleteToken();

    verify(() => storage.delete(key: PassengerStorageKeys.jwtToken)).called(1);
  });

  test('persists and restores a chat read timestamp per ride', () async {
    final readAt = DateTime.utc(2026, 9, 18, 12, 30);
    when(
      () => storage.write(
        key: PassengerStorageKeys.chatReadAt('ride-7'),
        value: readAt.toIso8601String(),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.read(key: PassengerStorageKeys.chatReadAt('ride-7')))
        .thenAnswer((_) async => readAt.toIso8601String());

    await sessionStore.saveChatReadAt('ride-7', readAt);
    final restored = await sessionStore.readChatReadAt('ride-7');

    expect(restored, readAt);
  });
}

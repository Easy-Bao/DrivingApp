import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/session/storage_keys.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late SessionStore sessionStore;
  late Map<String, String> stored;

  setUp(() {
    storage = MockFlutterSecureStorage();
    sessionStore = SessionStore(storage: storage);
    stored = {};
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) async {
      stored[call.namedArguments[#key] as String] =
          call.namedArguments[#value] as String;
    });
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((call) async => stored[call.namedArguments[#key]]);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((call) async {
      stored.remove(call.namedArguments[#key]);
    });
  });

  test('remembered sessions survive a new session store', () async {
    await sessionStore.configurePersistence(rememberMe: true);
    await sessionStore.saveToken('access');
    await sessionStore.saveRefreshToken('refresh');
    await sessionStore.savePassengerId('42');
    final reopened = SessionStore(storage: storage);
    expect(await reopened.readToken(), 'access');
    expect(await reopened.readRefreshToken(), 'refresh');
    expect(await reopened.readPassengerId(), '42');
  });

  test('unchecked sessions and refreshed tokens stay in memory only', () async {
    await sessionStore.saveToken('previous-access');
    await sessionStore.saveRefreshToken('previous-refresh');
    await sessionStore.savePassengerId('previous-user');
    await sessionStore.configurePersistence(rememberMe: false);
    await sessionStore.saveToken('access');
    await sessionStore.saveRefreshToken('refresh');
    await sessionStore.savePassengerId('42');
    await sessionStore.saveActiveRideId('ride-1');
    await sessionStore.saveToken('rotated-access');
    await sessionStore.saveRefreshToken('rotated-refresh');

    expect(await sessionStore.readToken(), 'rotated-access');
    expect(await sessionStore.readRefreshToken(), 'rotated-refresh');
    expect(await sessionStore.readPassengerId(), '42');
    expect(await sessionStore.readActiveRideId(), 'ride-1');
    expect(stored, isEmpty);
    final reopened = SessionStore(storage: storage);
    expect(await reopened.readToken(), isNull);
    expect(await reopened.readRefreshToken(), isNull);
    expect(await reopened.readPassengerId(), isNull);

    await sessionStore.clearAll();
    expect(await sessionStore.readToken(), isNull);
    expect(await sessionStore.readRefreshToken(), isNull);
    expect(await sessionStore.readPassengerId(), isNull);
  });

  test('clears only passenger-owned session keys', () async {
    await sessionStore.clearAll();

    for (final key in const [
      StorageKeys.accessToken,
      StorageKeys.refreshToken,
      StorageKeys.driverId,
      StorageKeys.passengerId,
      StorageKeys.activeRideId,
    ]) {
      verify(() => storage.delete(key: key)).called(1);
    }
    verifyNever(() => storage.deleteAll());
  });

  test('keeps the active ride out of a later account session', () async {
    await sessionStore.clearAll();

    verify(() => storage.delete(key: StorageKeys.activeRideId)).called(1);
  });

  test('keeps granular token deletion behavior', () async {
    await sessionStore.deleteToken();

    verify(() => storage.delete(key: StorageKeys.accessToken)).called(1);
  });

  test('persists and restores a chat read timestamp per ride', () async {
    final readAt = DateTime.utc(2026, 9, 18, 12, 30);
    when(
      () => storage.write(
        key: StorageKeys.chatReadAt('ride-7'),
        value: readAt.toIso8601String(),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.read(key: StorageKeys.chatReadAt('ride-7')))
        .thenAnswer((_) async => readAt.toIso8601String());

    await sessionStore.saveChatReadAt('ride-7', readAt);
    final restored = await sessionStore.readChatReadAt('ride-7');

    expect(restored, readAt);
  });

  test(
    'saves an ambiguous booking request and cancellation intent together',
    () async {
      await sessionStore.savePendingBidSessionCreation(
        idempotencyKey: 'retry-key-12345678',
        requestPayload: '{"pickup_name":"Pickup"}',
      );
      await sessionStore.requestPendingBidSessionCancellation();
      await sessionStore.attachPendingBidSessionId('request-31');

      final restored = await SessionStore(storage: storage)
          .readPendingBidSessionCreation();

      expect(restored?.idempotencyKey, 'retry-key-12345678');
      expect(restored?.requestPayload, '{"pickup_name":"Pickup"}');
      expect(restored?.cancelRequested, isTrue);
      expect(restored?.sessionId, 'request-31');
      expect(stored.keys, contains(StorageKeys.pendingBidSessionCreation));
      expect(
        stored.keys,
        isNot(contains('pending_bid_session_idempotency_key')),
      );
      expect(stored.keys, isNot(contains('pending_bid_session_payload')));
    },
  );
}

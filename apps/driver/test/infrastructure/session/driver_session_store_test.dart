import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver/src/infrastructure/session/driver_storage_keys.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late SessionStore sessionService;

  setUp(() {
    storage = MockFlutterSecureStorage();
    sessionService = SessionStore(storage: storage);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  test(
    'recognizes a persisted token and driver ID as an active session',
    () async {
      when(() => storage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => 'jwt-token');
      when(() => storage.read(key: StorageKeys.driverId))
          .thenAnswer((_) async => 'driver-1');

      expect(await sessionService.hasValidSession(), isTrue);
    },
  );

  test('rejects an incomplete persisted session', () async {
    when(() => storage.read(key: StorageKeys.accessToken))
        .thenAnswer((_) async => 'jwt-token');
    when(() => storage.read(key: StorageKeys.driverId))
        .thenAnswer((_) async => '');

    expect(await sessionService.hasValidSession(), isFalse);
  });

  test('deletes the cached active ride ID', () async {
    await sessionService.clearActiveRideId();

    verify(() => storage.delete(key: StorageKeys.activeRideId)).called(1);
    verifyNever(
      () => storage.write(
        key: StorageKeys.activeRideId,
        value: any(named: 'value'),
      ),
    );
  });

  test('persists and reads the refresh token', () async {
    when(() => storage.read(key: StorageKeys.refreshToken))
        .thenAnswer((_) async => 'refresh-jwt-token');

    await sessionService.saveRefreshToken('refresh-jwt-token');

    verify(
      () => storage.write(
        key: StorageKeys.refreshToken,
        value: 'refresh-jwt-token',
      ),
    ).called(1);
    expect(await sessionService.readRefreshToken(), 'refresh-jwt-token');
  });

  test('clears only driver-owned session keys', () async {
    await sessionService.clearSession();

    for (final key in const [
      StorageKeys.accessToken,
      StorageKeys.refreshToken,
      StorageKeys.driverId,
      StorageKeys.driverOnlineStatus,
      StorageKeys.driverOnlineSince,
      StorageKeys.passengerId,
      StorageKeys.activeRideId,
    ]) {
      verify(() => storage.delete(key: key)).called(1);
    }
    verifyNever(() => storage.deleteAll());
  });
}

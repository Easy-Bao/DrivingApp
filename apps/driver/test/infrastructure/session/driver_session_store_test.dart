import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver/src/infrastructure/session/driver_storage_keys.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late DriverSessionStore sessionService;

  setUp(() {
    storage = MockFlutterSecureStorage();
    sessionService = DriverSessionStore(storage: storage);
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
      when(() => storage.read(key: DriverStorageKeys.jwtToken))
          .thenAnswer((_) async => 'jwt-token');
      when(() => storage.read(key: DriverStorageKeys.driverId))
          .thenAnswer((_) async => 'driver-1');

      expect(await sessionService.hasValidDriverSession(), isTrue);
    },
  );

  test('rejects an incomplete persisted session', () async {
    when(() => storage.read(key: DriverStorageKeys.jwtToken))
        .thenAnswer((_) async => 'jwt-token');
    when(() => storage.read(key: DriverStorageKeys.driverId))
        .thenAnswer((_) async => '');

    expect(await sessionService.hasValidDriverSession(), isFalse);
  });

  test('persists and reads the refresh token', () async {
    when(() => storage.read(key: DriverStorageKeys.refreshToken))
        .thenAnswer((_) async => 'refresh-jwt-token');

    await sessionService.saveRefreshToken('refresh-jwt-token');

    verify(
      () => storage.write(
        key: DriverStorageKeys.refreshToken,
        value: 'refresh-jwt-token',
      ),
    ).called(1);
    expect(await sessionService.readRefreshToken(), 'refresh-jwt-token');
  });

  test('persists the UTC shift start time', () async {
    final startedAt = DateTime.utc(2026, 9, 23, 8);
    when(() => storage.read(key: DriverStorageKeys.driverOnlineSince))
        .thenAnswer((_) async => startedAt.toIso8601String());

    await sessionService.saveDriverOnlineSince(startedAt);

    verify(
      () => storage.write(
        key: DriverStorageKeys.driverOnlineSince,
        value: startedAt.toIso8601String(),
      ),
    ).called(1);
    expect(await sessionService.readDriverOnlineSince(), startedAt);
  });

  test('clears only driver-owned session keys', () async {
    await sessionService.clearSession();

    for (final key in const [
      DriverStorageKeys.jwtToken,
      DriverStorageKeys.refreshToken,
      DriverStorageKeys.driverId,
      DriverStorageKeys.driverOnlineStatus,
      DriverStorageKeys.driverOnlineSince,
      DriverStorageKeys.passengerId,
      DriverStorageKeys.activeRideId,
    ]) {
      verify(() => storage.delete(key: key)).called(1);
    }
    verifyNever(() => storage.deleteAll());
  });
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver/src/core/session/storage_keys.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('persists and reads driver last active timestamp', () async {
    final now = DateTime.utc(2026, 11, 5, 12, 30);
    when(() => storage.read(key: StorageKeys.driverLastActive))
        .thenAnswer((_) async => now.toIso8601String());

    await sessionService.saveDriverLastActive(now);

    verify(
      () => storage.write(
        key: StorageKeys.driverLastActive,
        value: now.toIso8601String(),
      ),
    ).called(1);
    expect(await sessionService.readDriverLastActive(), now);

    await sessionService.clearDriverLastActive();
    verify(() => storage.delete(key: StorageKeys.driverLastActive)).called(1);
  });

  test(
    'clears only driver-owned session keys and cached profile keys',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'driver_id': '42',
        'driver_name': 'Test Driver',
        'driver_phone': '+639171234567',
        'driver_email': 'driver@example.com',
        'vehicle_type': 'Sedan',
        'plate_number': 'ABC-123',
        'rating': '4.9',
        'unrelated_key': 'keep-me',
      });
      final preferences = await SharedPreferences.getInstance();
      final sessionWithPrefs = SessionStore(
        storage: storage,
        preferences: preferences,
      );

      await sessionWithPrefs.clearSession();

      for (final key in const [
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
        StorageKeys.driverId,
        StorageKeys.driverOnlineStatus,
        StorageKeys.driverOnlineSince,
        StorageKeys.driverLastActive,
        StorageKeys.passengerId,
        StorageKeys.activeRideId,
      ]) {
        verify(() => storage.delete(key: key)).called(1);
      }
      for (final key in StorageKeys.profileCacheKeys) {
        expect(preferences.getString(key), isNull);
      }
      expect(preferences.getString('unrelated_key'), 'keep-me');
      verifyNever(() => storage.deleteAll());
    },
  );
}

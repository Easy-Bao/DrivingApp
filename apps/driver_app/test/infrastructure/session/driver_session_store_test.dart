import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/infrastructure/session/driver_storage_keys.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';

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
  });

  test(
    'recognizes a persisted token and driver ID as an active session',
    () async {
      when(
        () => storage.read(key: DriverStorageKeys.jwtToken),
      ).thenAnswer((_) async => 'jwt-token');
      when(
        () => storage.read(key: DriverStorageKeys.driverId),
      ).thenAnswer((_) async => 'driver-1');

      expect(await sessionService.hasValidDriverSession(), isTrue);
    },
  );

  test('rejects an incomplete persisted session', () async {
    when(
      () => storage.read(key: DriverStorageKeys.jwtToken),
    ).thenAnswer((_) async => 'jwt-token');
    when(
      () => storage.read(key: DriverStorageKeys.driverId),
    ).thenAnswer((_) async => '');

    expect(await sessionService.hasValidDriverSession(), isFalse);
  });

  test('persists and reads the refresh token', () async {
    when(
      () => storage.read(key: DriverStorageKeys.refreshToken),
    ).thenAnswer((_) async => 'refresh-jwt-token');

    await sessionService.saveRefreshToken('refresh-jwt-token');

    verify(
      () => storage.write(
        key: DriverStorageKeys.refreshToken,
        value: 'refresh-jwt-token',
      ),
    ).called(1);
    expect(await sessionService.readRefreshToken(), 'refresh-jwt-token');
  });
}

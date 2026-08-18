import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/constants/storage_keys.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late SecureSessionService sessionService;

  setUp(() {
    storage = MockFlutterSecureStorage();
    sessionService = SecureSessionService(storage: storage);
  });

  test(
    'recognizes a persisted token and driver ID as an active session',
    () async {
      when(
        () => storage.read(key: StorageKeys.jwtToken),
      ).thenAnswer((_) async => 'jwt-token');
      when(
        () => storage.read(key: StorageKeys.driverId),
      ).thenAnswer((_) async => 'driver-1');

      expect(await sessionService.hasValidDriverSession(), isTrue);
    },
  );

  test('rejects an incomplete persisted session', () async {
    when(
      () => storage.read(key: StorageKeys.jwtToken),
    ).thenAnswer((_) async => 'jwt-token');
    when(
      () => storage.read(key: StorageKeys.driverId),
    ).thenAnswer((_) async => '');

    expect(await sessionService.hasValidDriverSession(), isFalse);
  });
}

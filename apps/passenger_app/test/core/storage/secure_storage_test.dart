import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/constants/storage_keys.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/storage/secure_storage.dart';

class MockSecureSessionService extends Mock implements SecureSessionService {}

void main() {
  late MockSecureSessionService secureSessionService;
  late SecureStorage secureStorage;

  setUp(() {
    secureSessionService = MockSecureSessionService();
    secureStorage = SecureStorage(secureSessionService);
  });

  test('delegates token operations to SecureSessionService', () async {
    when(() => secureSessionService.saveToken(any())).thenAnswer((_) async {});
    when(
      () => secureSessionService.readToken(),
    ).thenAnswer((_) async => 'jwt-token');
    when(() => secureSessionService.deleteToken()).thenAnswer((_) async {});

    await secureStorage.write(StorageKeys.jwtToken, 'jwt-token');
    final storedToken = await secureStorage.read(StorageKeys.jwtToken);
    await secureStorage.delete(StorageKeys.jwtToken);

    expect(storedToken, 'jwt-token');
    verify(() => secureSessionService.saveToken('jwt-token')).called(1);
    verify(() => secureSessionService.readToken()).called(1);
    verify(() => secureSessionService.deleteToken()).called(1);
  });

  test('rejects unsupported keys that are not session-critical', () {
    expect(
      () => secureStorage.write('unsupported_key', 'value'),
      throwsArgumentError,
    );
  });

  test('delegates refresh-token operations to SecureSessionService', () async {
    when(
      () => secureSessionService.saveRefreshToken(any()),
    ).thenAnswer((_) async {});
    when(
      () => secureSessionService.readRefreshToken(),
    ).thenAnswer((_) async => 'refresh-token');
    when(
      () => secureSessionService.deleteRefreshToken(),
    ).thenAnswer((_) async {});

    await secureStorage.write(StorageKeys.refreshToken, 'refresh-token');
    final storedToken = await secureStorage.read(StorageKeys.refreshToken);
    await secureStorage.delete(StorageKeys.refreshToken);

    expect(storedToken, 'refresh-token');
    verify(
      () => secureSessionService.saveRefreshToken('refresh-token'),
    ).called(1);
    verify(() => secureSessionService.readRefreshToken()).called(1);
    verify(() => secureSessionService.deleteRefreshToken()).called(1);
  });
}

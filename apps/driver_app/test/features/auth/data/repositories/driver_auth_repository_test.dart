import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/constants/api_endpoints.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/auth/data/repositories/driver_auth_repository.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource remoteDataSource;
  late MockSecureSessionService secureSessionService;
  late DriverAuthRepositoryImpl repository;

  setUp(() async {
    remoteDataSource = MockAuthRemoteDataSource();
    secureSessionService = MockSecureSessionService();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = DriverAuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      secureSessionService: secureSessionService,
    );

    when(() => secureSessionService.saveToken(any())).thenAnswer((_) async {});
    when(
      () => secureSessionService.saveRefreshToken(any()),
    ).thenAnswer((_) async {});
    when(
      () => secureSessionService.saveDriverId(any()),
    ).thenAnswer((_) async {});
  });

  test('normalizes numeric driver IDs before persisting the session', () async {
    when(
      () => remoteDataSource.postData(
        ApiEndpoints.driverLogin,
        requestBody: {
          'email': 'driver@example.com',
          'password': 'secret-password',
        },
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'token': 'jwt-token',
        'refreshToken': 'refresh-jwt-token',
        'user': <String, dynamic>{
          'id': 42,
          'name': 'Test Driver',
          'email': 'driver@example.com',
          'vehicleType': 'sedan',
          'plateNumber': 'ABC-123',
          'rating': 4.75,
        },
      },
    );

    final result = await repository.authenticate(
      email: 'driver@example.com',
      password: 'secret-password',
    );

    late DriverAuthCredentials credentials;
    result.fold(
      (failure) => fail('Expected credentials, got ${failure.message}'),
      (value) => credentials = value,
    );
    expect(credentials.driverId, '42');
    expect(credentials.driverName, 'Test Driver');
    expect(credentials.rating, 4.75);
    verify(() => secureSessionService.saveToken('jwt-token')).called(1);
    verify(
      () => secureSessionService.saveRefreshToken('refresh-jwt-token'),
    ).called(1);
    verify(() => secureSessionService.saveDriverId('42')).called(1);
  });

  test(
    'uses the authenticated user ID from a profile-shaped response',
    () async {
      when(
        () => remoteDataSource.postData(
          ApiEndpoints.driverLogin,
          requestBody: {
            'email': 'driver@example.com',
            'password': 'secret-password',
          },
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'token': 'jwt-token',
          'driver': <String, dynamic>{
            'id': 7,
            'userId': 42,
            'name': 'Test Driver',
            'email': 'driver@example.com',
          },
        },
      );

      final result = await repository.authenticate(
        email: 'driver@example.com',
        password: 'secret-password',
      );

      expect(result.isRight(), isTrue);
      verify(() => secureSessionService.saveDriverId('42')).called(1);
    },
  );

  test('returns a server failure for malformed session data', () async {
    when(
      () => remoteDataSource.postData(
        ApiEndpoints.driverLogin,
        requestBody: any(named: 'requestBody'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'token': 'jwt-token',
        'user': <String, dynamic>{},
      },
    );

    final result = await repository.authenticate(
      email: 'driver@example.com',
      password: 'secret-password',
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => secureSessionService.saveToken(any()));
    verifyNever(() => secureSessionService.saveDriverId(any()));
  });
}

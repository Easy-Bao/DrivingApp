import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/features/auth/data/driver_auth_endpoints.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/auth/data/data_sources/driver_auth_remote_data_source.dart';
import 'package:driver_app/src/features/auth/data/repositories/driver_auth_repository_impl.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource extends Mock
    implements DriverAuthRemoteDataSource {}

class MockSecureSessionService extends Mock implements DriverSessionStore {}

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
        DriverAuthEndpoints.login,
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
          DriverAuthEndpoints.login,
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
        DriverAuthEndpoints.login,
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

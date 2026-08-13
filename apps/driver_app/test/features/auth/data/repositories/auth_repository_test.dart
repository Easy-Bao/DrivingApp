import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource remoteDataSource;
  late MockSecureSessionService secureSessionService;
  late AuthRepository repository;

  setUp(() async {
    remoteDataSource = MockAuthRemoteDataSource();
    secureSessionService = MockSecureSessionService();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = AuthRepository(
      remoteDataSource: remoteDataSource,
      secureSessionService: secureSessionService,
    );

    when(() => secureSessionService.saveToken(any())).thenAnswer((_) async {});
    when(
      () => secureSessionService.saveDriverId(any()),
    ).thenAnswer((_) async {});
  });

  test('normalizes numeric driver IDs before persisting the session', () async {
    when(
      () => remoteDataSource.authenticateDriver(
        email: 'driver@example.com',
        password: 'secret-password',
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'token': 'jwt-token',
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

    final result = await repository.authenticateDriver(
      email: 'driver@example.com',
      password: 'secret-password',
    );

    late AuthCredentials credentials;
    result.fold(
      (failure) => fail('Expected credentials, got ${failure.message}'),
      (value) => credentials = value,
    );
    expect(credentials.driverId, '42');
    expect(credentials.driverName, 'Test Driver');
    expect(credentials.rating, 4.75);
    verify(() => secureSessionService.saveToken('jwt-token')).called(1);
    verify(() => secureSessionService.saveDriverId('42')).called(1);
  });

  test(
    'uses the authenticated user ID from a profile-shaped response',
    () async {
      when(
        () => remoteDataSource.authenticateDriver(
          email: 'driver@example.com',
          password: 'secret-password',
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

      final result = await repository.authenticateDriver(
        email: 'driver@example.com',
        password: 'secret-password',
      );

      expect(result.isRight(), isTrue);
      verify(() => secureSessionService.saveDriverId('42')).called(1);
    },
  );

  test('returns a server failure for malformed session data', () async {
    when(
      () => remoteDataSource.authenticateDriver(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'token': 'jwt-token',
        'user': <String, dynamic>{},
      },
    );

    final result = await repository.authenticateDriver(
      email: 'driver@example.com',
      password: 'secret-password',
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => secureSessionService.saveToken(any()));
    verifyNever(() => secureSessionService.saveDriverId(any()));
  });
}

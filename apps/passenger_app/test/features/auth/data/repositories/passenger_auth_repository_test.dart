import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/auth/data/passenger_auth_endpoints.dart';
import 'package:passenger_app/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger_app/src/features/auth/data/data_sources/passenger_auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/data/repositories/passenger_auth_repository.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource extends Mock
    implements PassengerAuthRemoteDataSource {}

class MockSecureSessionService extends Mock implements PassengerSessionStore {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource remoteDataSource;
  late MockSecureSessionService secureSessionService;
  late SharedPreferences preferences;
  late PassengerAuthRepositoryImpl repository;

  setUp(() async {
    remoteDataSource = MockAuthRemoteDataSource();
    secureSessionService = MockSecureSessionService();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    repository = PassengerAuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      secureSessionService: secureSessionService,
      preferences: preferences,
    );

    when(() => secureSessionService.saveToken(any())).thenAnswer((_) async {});
    when(
      () => secureSessionService.saveRefreshToken(any()),
    ).thenAnswer((_) async {});
    when(
      () => secureSessionService.savePassengerId(any()),
    ).thenAnswer((_) async {});
  });

  group('AuthRepository.authenticate', () {
    test(
      'maps the server session and persists sensitive identity securely',
      () async {
        when(
          () => remoteDataSource.postData(
            PassengerAuthEndpoints.login,
            requestBody: {
              'email': 'passenger@example.com',
              'password': 'secret-password',
            },
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'token': 'jwt-token',
            'refreshToken': 'refresh-jwt-token',
            'user': <String, dynamic>{
              'id': 42,
              'name': 'Test Passenger',
              'email': 'passenger@example.com',
              'phone': '+639170000001',
            },
            'needsVerification': true,
          },
        );

        final result = await repository.authenticate(
          email: 'passenger@example.com',
          password: 'secret-password',
        );

        late PassengerAuthCredentials credentials;
        result.fold(
          (failure) => fail('Expected credentials, got ${failure.message}'),
          (value) => credentials = value,
        );
        expect(
          credentials,
          const PassengerAuthCredentials(
            passengerId: '42',
            passengerName: 'Test Passenger',
            passengerEmail: 'passenger@example.com',
            passengerPhone: '+639170000001',
            token: 'jwt-token',
            refreshToken: 'refresh-jwt-token',
            needsVerification: true,
          ),
        );
        verify(() => secureSessionService.saveToken('jwt-token')).called(1);
        verify(
          () => secureSessionService.saveRefreshToken('refresh-jwt-token'),
        ).called(1);
        verify(() => secureSessionService.savePassengerId('42')).called(1);

        expect(preferences.containsKey('jwt_token'), isFalse);
        expect(preferences.containsKey('passenger_id'), isFalse);
      },
    );

    test(
      'returns a failure instead of empty credentials for malformed data',
      () async {
        when(
          () => remoteDataSource.postData(
            PassengerAuthEndpoints.login,
            requestBody: any(named: 'requestBody'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'token': '',
            'user': <String, dynamic>{},
            'needsVerification': false,
          },
        );

        final result = await repository.authenticate(
          email: 'passenger@example.com',
          password: 'secret-password',
        );

        expect(result.isLeft(), isTrue);
        verifyNever(() => secureSessionService.saveToken(any()));
        verifyNever(() => secureSessionService.savePassengerId(any()));
      },
    );

    test('returns a failure when the remote data source throws', () async {
      when(
        () => remoteDataSource.postData(
          PassengerAuthEndpoints.login,
          requestBody: any(named: 'requestBody'),
        ),
      ).thenThrow(Exception('gateway unavailable'));

      final result = await repository.authenticate(
        email: 'passenger@example.com',
        password: 'secret-password',
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => secureSessionService.saveToken(any()));
      verifyNever(() => secureSessionService.savePassengerId(any()));
    });
  });

  test(
    'verifyOtp persists the session returned by the verification endpoint',
    () async {
      when(
        () => remoteDataSource.postData(
          PassengerAuthEndpoints.verifyOtp,
          requestBody: {'email': 'passenger@example.com', 'code': '123456'},
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'token': 'verified-jwt',
          'user': <String, dynamic>{
            'id': 42,
            'name': 'Test Passenger',
            'email': 'passenger@example.com',
            'phone': '+639170000001',
          },
        },
      );

      final result = await repository.verifyOtp(
        email: 'passenger@example.com',
        code: '123456',
      );

      late PassengerAuthCredentials credentials;
      result.fold(
        (failure) => fail('Expected credentials, got ${failure.message}'),
        (value) => credentials = value,
      );
      expect(credentials.passengerId, '42');
      expect(credentials.token, 'verified-jwt');
      verify(() => secureSessionService.saveToken('verified-jwt')).called(1);
      verify(() => secureSessionService.saveRefreshToken('')).called(1);
      verify(() => secureSessionService.savePassengerId('42')).called(1);
      verifyNever(
        () => remoteDataSource.postData(
          PassengerAuthEndpoints.login,
          requestBody: any(named: 'requestBody'),
        ),
      );
    },
  );

  test('registerPassenger persists an immediately usable session', () async {
    when(
      () => remoteDataSource.postData(
        PassengerAuthEndpoints.register,
        requestBody: {
          'name': 'Test Passenger',
          'email': 'passenger@example.com',
          'phone': '+639170000001',
          'password': 'secret-password',
        },
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'token': 'registered-jwt',
        'user': <String, dynamic>{
          'id': 42,
          'name': 'Test Passenger',
          'email': 'passenger@example.com',
          'phone': '+639170000001',
        },
        'needsVerification': false,
      },
    );

    final result = await repository.registerPassenger(
      name: 'Test Passenger',
      email: 'passenger@example.com',
      phone: '+639170000001',
      password: 'secret-password',
    );

    expect(result.isRight(), isTrue);
    verify(() => secureSessionService.saveToken('registered-jwt')).called(1);
    verify(() => secureSessionService.saveRefreshToken('')).called(1);
    verify(() => secureSessionService.savePassengerId('42')).called(1);
  });
}

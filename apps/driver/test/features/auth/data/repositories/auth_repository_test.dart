import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/features/auth/data/datasources/auth_endpoints.dart';
import 'package:driver/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureSessionService extends Mock implements SessionStore {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource remoteDataSource;
  late MockSecureSessionService secureSessionService;
  late AuthRepositoryImpl repository;

  setUp(() async {
    remoteDataSource = MockAuthRemoteDataSource();
    secureSessionService = MockSecureSessionService();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      secureSessionService: secureSessionService,
    );

    when(() => secureSessionService.saveToken(any())).thenAnswer((_) async {});
    when(() => secureSessionService.saveRefreshToken(any()))
        .thenAnswer((_) async {});
    when(() => secureSessionService.saveDriverId(any()))
        .thenAnswer((_) async {});
  });

  test('normalizes numeric driver IDs before persisting the session', () async {
    when(
      () => remoteDataSource.postData(
        AccountAuthEndpoints.login,
        requestBody: {
          'email': 'driver@example.com',
          'password': 'secret-password',
          'role': 'driver',
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

    late AuthCredentials credentials;
    result.fold(
      (failure) => fail('Expected credentials, got ${failure.message}'),
      (value) => credentials = value,
    );
    expect(credentials.driverId, '42');
    expect(credentials.driverName, 'Test Driver');
    expect(credentials.rating, 4.75);
    verify(() => secureSessionService.saveToken('jwt-token')).called(1);
    verify(() => secureSessionService.saveRefreshToken('refresh-jwt-token'))
        .called(1);
    verify(() => secureSessionService.saveDriverId('42')).called(1);
  });

  test(
    'uses the authenticated user ID from a profile-shaped response',
    () async {
      when(
        () => remoteDataSource.postData(
          AccountAuthEndpoints.login,
          requestBody: {
            'email': 'driver@example.com',
            'password': 'secret-password',
            'role': 'driver',
          },
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'token': 'jwt-token',
          'refreshToken': 'refresh-jwt-token',
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

      expect(result.isOk, isTrue);
      verify(() => secureSessionService.saveDriverId('42')).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vehicle_type'), isEmpty);
      expect(prefs.getString('plate_number'), isEmpty);
    },
  );

  test('returns a server failure for malformed session data', () async {
    when(
      () => remoteDataSource.postData(
        AccountAuthEndpoints.login,
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

    expect(result.isErr, isTrue);
    verifyNever(() => secureSessionService.saveToken(any()));
    verifyNever(() => secureSessionService.saveRefreshToken(any()));
    verifyNever(() => secureSessionService.saveDriverId(any()));
  });

  test(
    'rejects a session without a refresh token before persistence',
    () async {
      when(
        () => remoteDataSource.postData(
          AccountAuthEndpoints.login,
          requestBody: any(named: 'requestBody'),
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'token': 'jwt-token',
          'user': <String, dynamic>{
            'id': 42,
            'name': 'Test Driver',
            'email': 'driver@example.com',
          },
        },
      );

      final result = await repository.authenticate(
        email: 'driver@example.com',
        password: 'secret-password',
      );

      expect(result.isErr, isTrue);
      verifyNever(() => secureSessionService.saveToken(any()));
      verifyNever(() => secureSessionService.saveRefreshToken(any()));
      verifyNever(() => secureSessionService.saveDriverId(any()));
    },
  );

  test(
    'resetPassword succeeds only when response Body indicates success',
    () async {
      when(
        () => remoteDataSource.postJson(
          AccountAuthEndpoints.forgotPassword,
          requestBody: {'email': 'driver@example.com'},
        ),
      ).thenAnswer((_) async => <String, dynamic>{'success': true});

      final okResult = await repository.resetPassword(
        email: 'driver@example.com',
      );
      expect(okResult.isOk, isTrue);

      when(
        () => remoteDataSource.postJson(
          AccountAuthEndpoints.forgotPassword,
          requestBody: {'email': 'driver@example.com'},
        ),
      ).thenAnswer((_) async => <String, dynamic>{'success': false});

      final errResult = await repository.resetPassword(
        email: 'driver@example.com',
      );
      expect(errResult.isErr, isTrue);
    },
  );

  group('password recovery validation failures', () {
    test('maps HTTP 400 on resetPassword to InvalidEmailFailure with clear message', () async {
      when(
        () => remoteDataSource.postJson(
          AccountAuthEndpoints.forgotPassword,
          requestBody: {'email': 'bad@email'},
        ),
      ).thenThrow(
        const ServerException(
          message: 'Enter a valid email address.',
          statusCode: 400,
        ),
      );

      final result = await repository.resetPassword(email: 'bad@email');
      result.fold((failure) {
        expect(failure, isA<InvalidEmailFailure>());
        expect(
          ErrorHandler.getErrorMessage(failure),
          'Enter a valid email address.',
        );
      }, (_) => fail('Expected failure'));
    });

    test(
      'maps HTTP 400 on verifyResetOtp to InvalidVerificationCodeFailure',
      () async {
        when(
          () => remoteDataSource.postJson(
            AccountAuthEndpoints.verifyResetOtp,
            requestBody: {'email': 'driver@example.com', 'code': '000000'},
          ),
        ).thenThrow(
          const ServerException(
            message: 'invalid or expired otp',
            statusCode: 400,
          ),
        );

        final result = await repository.verifyResetOtp(
          email: 'driver@example.com',
          code: '000000',
        );
        result.fold((failure) {
          expect(failure, isA<InvalidVerificationCodeFailure>());
          expect(
            ErrorHandler.getErrorMessage(failure),
            'That verification code is invalid or expired. Try again.',
          );
        }, (_) => fail('Expected failure'));
      },
    );

    test(
      'maps HTTP 400 on confirmPasswordReset to InvalidVerificationCodeFailure',
      () async {
        when(
          () => remoteDataSource.postJson(
            AccountAuthEndpoints.resetPassword,
            requestBody: {
              'email': 'driver@example.com',
              'code': '000000',
              'newPassword': 'new-password',
            },
          ),
        ).thenThrow(
          const ServerException(
            message: 'invalid or expired otp',
            statusCode: 400,
          ),
        );

        final result = await repository.confirmPasswordReset(
          email: 'driver@example.com',
          code: '000000',
          newPassword: 'new-password',
        );
        result.fold((failure) {
          expect(failure, isA<InvalidVerificationCodeFailure>());
          expect(
            ErrorHandler.getErrorMessage(failure),
            'That verification code is invalid or expired. Request a new code and try again.',
          );
        }, (_) => fail('Expected failure'));
      },
    );
  });
}

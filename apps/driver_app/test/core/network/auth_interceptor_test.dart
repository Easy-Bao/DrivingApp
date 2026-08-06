import 'package:dio/dio.dart';
import 'package:driver_app/src/core/network/interceptors/auth_interceptor.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

void main() {
  test('does not send the session token to another origin', () async {
    final secureSessionService = MockSecureSessionService();
    final handler = MockRequestInterceptorHandler();
    final requestOptions = RequestOptions(
      baseUrl: 'https://attacker.example',
      path: '/collect',
    );
    when(
      () => secureSessionService.readToken(),
    ).thenAnswer((_) async => 'jwt-token');

    await AuthInterceptor(
      secureSessionService,
      allowedBaseUri: Uri.parse('https://api.example'),
    ).onRequest(requestOptions, handler);

    expect(requestOptions.headers, isNot(contains('Authorization')));
    verify(() => handler.next(requestOptions)).called(1);
  });
}

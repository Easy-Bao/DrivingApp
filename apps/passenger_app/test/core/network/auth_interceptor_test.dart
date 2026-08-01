import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/network/interceptors/auth_interceptor.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

void main() {
  test('adds the securely stored token to authenticated requests', () async {
    final secureSessionService = MockSecureSessionService();
    final handler = MockRequestInterceptorHandler();
    final requestOptions = RequestOptions(path: '/passengers/passenger-42');
    when(
      () => secureSessionService.readToken(),
    ).thenAnswer((_) async => 'jwt-token');

    await AuthInterceptor(
      secureSessionService,
    ).onRequest(requestOptions, handler);

    expect(requestOptions.headers['Authorization'], 'Bearer jwt-token');
    verify(() => handler.next(requestOptions)).called(1);
  });
}

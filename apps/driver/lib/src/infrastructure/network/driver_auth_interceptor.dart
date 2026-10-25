import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';

class AuthInterceptor extends BearerAuthInterceptor {
  AuthInterceptor(
    SessionStore secureSessionService, {
    super.dio,
    Dio? refreshClient,
    super.allowedBaseUri,
    RefreshableTokenProvider? tokenProvider,
  }) : super(
         tokenProvider:
             tokenProvider ??
             RefreshableTokenProvider(
               readAccessToken: secureSessionService.readToken,
               readRefreshToken: secureSessionService.readRefreshToken,
               saveAccessToken: secureSessionService.saveToken,
               saveRefreshToken: secureSessionService.saveRefreshToken,
               clearSession: secureSessionService.clearSession,
               refreshClient: refreshClient,
             ),
       );
}

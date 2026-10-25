import 'dart:async';

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';

class AuthInterceptor extends BearerAuthInterceptor {
  AuthInterceptor(
    SessionStore secureSessionService, {
    super.dio,
    Dio? refreshClient,
    super.allowedBaseUri,
    FutureOr<void> Function()? onSessionExpired,
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
               onSessionExpired: onSessionExpired,
             ),
       );
}

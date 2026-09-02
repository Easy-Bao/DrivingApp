import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// Supplies the current access token to HTTP and long-lived transports.
///
/// Access tokens are intentionally decoded only to read their expiry. The
/// server remains responsible for validating the token signature and claims.
/// A single refresh request is shared by concurrent callers so a foreground
/// resume cannot create a refresh stampede.
final class RefreshableTokenProvider({
  required Future<String?> Function() readAccessToken,
  required Future<String?> Function() readRefreshToken,
  required Future<void> Function(String token) saveAccessToken,
  required Future<void> Function(String token) saveRefreshToken,
  required Future<void> Function() clearSession,
  Dio? refreshClient,
  FutureOr<void> Function()? onSessionExpired,
  Duration refreshSkew = const Duration(seconds: 30),
}) {
  static const _refreshTokenPath = '/api/v1/auth/refresh';

  final Future<String?> Function() _readAccessToken = readAccessToken;
  final Future<String?> Function() _readRefreshToken = readRefreshToken;
  final Future<void> Function(String token) _saveAccessToken = saveAccessToken;
  final Future<void> Function(String token) _saveRefreshToken =
      saveRefreshToken;
  final Future<void> Function() _clearSession = clearSession;
  final Dio? _refreshClient = refreshClient;
  final FutureOr<void> Function()? _onSessionExpired = onSessionExpired;
  final Duration _refreshSkew = refreshSkew;

  Future<String?>? _refreshInFlight;
  bool _sessionExpiryNotified = false;

  /// Returns a usable token, refreshing it before it expires when possible.
  Future<String?> getToken() async {
    final token = (await _readAccessToken())?.trim();
    if (token == null || token.isEmpty) {
      final refreshToken = (await _readRefreshToken())?.trim();
      if (refreshToken == null || refreshToken.isEmpty) return null;
      return refreshAccessToken();
    }

    final expiresAt = _readExpiry(token);
    if (expiresAt == null ||
        expiresAt.isAfter(DateTime.now().toUtc().add(_refreshSkew))) {
      return token;
    }

    return refreshAccessToken();
  }

  /// Refreshes the access token once for all concurrent callers.
  Future<String?> refreshAccessToken() {
    final pending = _refreshInFlight;
    if (pending != null) return pending;

    late final Future<String?> trackedRefresh;
    trackedRefresh = _performRefresh().whenComplete(() {
      if (identical(_refreshInFlight, trackedRefresh)) {
        _refreshInFlight = null;
      }
    });
    _refreshInFlight = trackedRefresh;
    return trackedRefresh;
  }

  Future<String?> _performRefresh() async {
    final refreshClient = _refreshClient;
    if (refreshClient == null) return null;

    final refreshToken = (await _readRefreshToken())?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    try {
      final response = await refreshClient.post<Object?>(
        _refreshTokenPath,
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {'skipAuthToken': true, 'skipAuthRefresh': true},
        ),
      );
      final payload = _extractPayload(response.data);
      final accessToken = _stringValue(payload?['token']).trim();
      if (accessToken.isEmpty) {
        await _expireSession();
        return null;
      }

      final rotatedRefreshToken = _stringValue(payload?['refreshToken']).trim();
      await _saveAccessToken(accessToken);
      await _saveRefreshToken(
        rotatedRefreshToken.isEmpty ? refreshToken : rotatedRefreshToken,
      );
      _sessionExpiryNotified = false;
      return accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _expireSession();
      }
      return null;
    } catch (_) {
      // A timeout, connection loss, or transient response must not sign out a
      // user. The next authenticated operation can try the refresh again.
      return null;
    }
  }

  Map<String, dynamic>? _extractPayload(Object? responseData) {
    if (responseData is! Map) return null;
    final data = responseData['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(responseData);
  }

  Future<void> _expireSession() async {
    try {
      await _clearSession();
    } catch (_) {
      // Session expiry notification must not be blocked by storage cleanup.
    }
    if (_sessionExpiryNotified) return;
    _sessionExpiryNotified = true;
    try {
      await _onSessionExpired?.call();
    } catch (_) {
      // The session is already treated as expired by the caller.
    }
  }

  DateTime? _readExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final rawExpiry = payload['exp'];
      final seconds = rawExpiry is num
          ? rawExpiry.toDouble()
          : double.tryParse(rawExpiry?.toString() ?? '');
      if (seconds == null || !seconds.isFinite) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        (seconds * 1000).round(),
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  String _stringValue(Object? value) => value?.toString() ?? '';
}

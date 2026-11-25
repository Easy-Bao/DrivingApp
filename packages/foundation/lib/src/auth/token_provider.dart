import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/src/auth/endpoints.dart';
import 'package:foundation/src/network/bearer_auth_interceptor.dart';
import 'package:foundation/src/network/offset_page.dart';

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
  FutureOr<bool> Function()? hasActiveMission,
  Duration refreshSkew = const Duration(seconds: 30),
  Duration refreshFailureCooldown = const Duration(seconds: 5),
}) {
  final Future<String?> Function() _readAccessToken = readAccessToken;
  final Future<String?> Function() _readRefreshToken = readRefreshToken;
  final Future<void> Function(String token) _saveAccessToken = saveAccessToken;
  final Future<void> Function(String token) _saveRefreshToken =
      saveRefreshToken;
  final Future<void> Function() _clearSession = clearSession;
  final Dio? _refreshClient = refreshClient;
  final FutureOr<void> Function()? _onSessionExpired = onSessionExpired;
  FutureOr<bool> Function()? _hasActiveMission = hasActiveMission;
  final Duration _refreshSkew = refreshSkew;
  final Duration _refreshFailureCooldown = refreshFailureCooldown;

  Future<String?>? _refreshInFlight;
  DateTime? _refreshBlockedUntil;
  bool _sessionExpiryNotified = false;
  bool _deferredExpiryPending = false;

  static const Duration _maxRetryAfter = Duration(minutes: 5);

  bool get isDeferredExpiryPending => _deferredExpiryPending;

  /// Resets transient cooldown and expiry flags after a fresh sign-in.
  void reset() {
    _refreshBlockedUntil = null;
    _sessionExpiryNotified = false;
    _deferredExpiryPending = false;
  }

  // ignore: use_setters_to_change_properties
  void registerActiveMissionChecker(FutureOr<bool> Function() checker) {
    _hasActiveMission = checker;
  }

  Future<String?> getToken() async {
    final pendingRefresh = _refreshInFlight;
    if (pendingRefresh != null) {
      return pendingRefresh;
    }

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

  Future<String?> refreshAccessToken() {
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    final blockedUntil = _refreshBlockedUntil;
    if (blockedUntil != null && DateTime.now().toUtc().isBefore(blockedUntil)) {
      return Future<String?>.value(null);
    }

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
        AuthEndpoints.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {skipAuthTokenExtraKey: true, skipAuthRefreshExtraKey: true},
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
      _refreshBlockedUntil = null;
      _sessionExpiryNotified = false;
      _deferredExpiryPending = false;
      return accessToken;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) {
        _refreshBlockedUntil = DateTime.now().toUtc().add(_retryAfter(error));
      } else if (statusCode == 401 || statusCode == 403) {
        await _expireSession();
        if (_deferredExpiryPending) {
          _refreshBlockedUntil = DateTime.now().toUtc().add(
            _refreshFailureCooldown,
          );
        }
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
    try {
      final root = decodeObjectMap(responseData);
      final data = root['data'];
      if (data is Map) return decodeObjectMap(data);
      return root;
    } on FormatException {
      return null;
    }
  }

  Future<void> _expireSession() async {
    final checker = _hasActiveMission;
    if (checker != null) {
      var inProgress = true;
      try {
        inProgress = await checker();
      } catch (_) {
        // Fail safe when mission status cannot be read so an active trip is
        // never interrupted by a transient checker failure.
        inProgress = true;
      }
      if (inProgress) {
        _deferredExpiryPending = true;
        return;
      }
    }
    _deferredExpiryPending = false;
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

  Future<void> flushDeferredExpiry() async {
    if (!_deferredExpiryPending) return;
    _sessionExpiryNotified = false;
    await _expireSession();
  }

  Duration _retryAfter(DioException error) {
    final rawValue = error.response?.headers.value('retry-after')?.trim();
    if (rawValue != null && rawValue.isNotEmpty) {
      final seconds = int.tryParse(rawValue);
      if (seconds != null && seconds > 0) {
        final duration = Duration(seconds: seconds);
        return duration > _maxRetryAfter ? _maxRetryAfter : duration;
      }
      try {
        final parsedDate = HttpDate.parse(rawValue).toUtc();
        final remaining = parsedDate.difference(DateTime.now().toUtc());
        if (remaining > Duration.zero) {
          return remaining > _maxRetryAfter ? _maxRetryAfter : remaining;
        }
      } on HttpException {
        // Ignore unparseable Retry-After date and fall back to default cooldown.
      }
    }
    return _refreshFailureCooldown;
  }

  DateTime? _readExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
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

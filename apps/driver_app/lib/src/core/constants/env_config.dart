import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_core/shared_core.dart';

enum AppEnvironment { development, staging, production }

class EnvConfig {
  EnvConfig._();

  static const AppEnvironment currentEnvironment = AppEnvironment.development;
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
  );
  static const _offlineMode = String.fromEnvironment('OFFLINE_MODE');
  static const _physicalDevice = String.fromEnvironment('PHYSICAL_DEVICE');
  static const _androidEmulatorLoopbackHost = String.fromEnvironment(
    'ANDROID_EMULATOR_LOOPBACK_HOST',
  );

  static String? get mapboxPublicToken {
    final token = _value('MAPBOX_PUBLIC_TOKEN', _mapboxPublicToken);
    return token == null || token.isEmpty ? null : token;
  }

  static bool get offlineMode =>
      _value('OFFLINE_MODE', _offlineMode)?.toLowerCase() == 'true';

  static Uri get apiBaseUri => _configuredUri();
  static Uri get driverServiceUri => apiBaseUri;
  static Uri get authServiceUri => apiBaseUri;
  static Uri get tripServiceUri => apiBaseUri;
  static Uri get placeServiceUri => apiBaseUri;
  static Uri get httpBaseUri => apiBaseUri;
  static String get httpBaseUrl => httpBaseUri.toString();

  static Uri get webSocketBaseUri {
    final uri = apiBaseUri;
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
  }

  static String get webSocketBaseUrl => webSocketBaseUri.toString();

  static Uri _configuredUri() {
    final rawUrl = _value('API_BASE_URL', _apiBaseUrl);
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      throw StateError(
        'Security Configuration Error: API_BASE_URL is required.',
      );
    }
    late Uri uri;
    try {
      uri = parseApiBaseUri(rawUrl);
    } on FormatException {
      throw StateError(
        'Security Configuration Error: API_BASE_URL must be an HTTP(S) origin.',
      );
    }
    final physicalDevice =
        _value('PHYSICAL_DEVICE', _physicalDevice)?.toLowerCase() == 'true';
    if (!physicalDevice &&
        !kIsWeb &&
        Platform.isAndroid &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      final loopbackHost = _value(
        'ANDROID_EMULATOR_LOOPBACK_HOST',
        _androidEmulatorLoopbackHost,
      );
      if (loopbackHost == null || loopbackHost.trim().isEmpty) {
        throw StateError(
          'Security Configuration Error: ANDROID_EMULATOR_LOOPBACK_HOST is required for local Android URLs.',
        );
      }
      try {
        uri = parseApiBaseUri(
          uri.replace(host: loopbackHost.trim()).toString(),
        );
      } on FormatException {
        throw StateError(
          'Security Configuration Error: ANDROID_EMULATOR_LOOPBACK_HOST must be a valid host.',
        );
      }
    }
    return uri;
  }

  static String? _value(String key, String? dartDefineValue) {
    if (dartDefineValue != null && dartDefineValue.trim().isNotEmpty) {
      return dartDefineValue;
    }
    return dotenv.env[key];
  }
}

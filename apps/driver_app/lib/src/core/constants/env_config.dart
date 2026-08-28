import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_core/shared_core.dart';

class EnvConfig {
  EnvConfig._();

  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
  );
  static const _physicalDevice = String.fromEnvironment('PHYSICAL_DEVICE');
  static const _usesAdbReverse = String.fromEnvironment(
    'ANDROID_USE_ADB_REVERSE',
  );
  static const _androidEmulatorLoopbackHost = String.fromEnvironment(
    'ANDROID_EMULATOR_LOOPBACK_HOST',
  );
  static const _backgroundTelemetry = String.fromEnvironment(
    'ENABLE_DRIVER_BACKGROUND_TELEMETRY',
  );

  static String? get mapboxPublicToken {
    final token = _value('MAPBOX_PUBLIC_TOKEN', _mapboxPublicToken)?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  static bool get backgroundTelemetryEnabled =>
      _flag('ENABLE_DRIVER_BACKGROUND_TELEMETRY', _backgroundTelemetry);

  static Uri get apiBaseUri {
    final rawUrl = _value('API_BASE_URL', _apiBaseUrl);
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      throw StateError(
        'Security Configuration Error: API_BASE_URL is required.',
      );
    }

    try {
      return resolveMobileApiBaseUri(
        rawUrl: rawUrl,
        allowInsecureHttp: !kReleaseMode,
        isAndroid: !kIsWeb && Platform.isAndroid,
        isPhysicalDevice: _flag('PHYSICAL_DEVICE', _physicalDevice),
        usesAdbReverse: _flag('ANDROID_USE_ADB_REVERSE', _usesAdbReverse),
        androidEmulatorLoopbackHost: _value(
          'ANDROID_EMULATOR_LOOPBACK_HOST',
          _androidEmulatorLoopbackHost,
        ),
      );
    } on FormatException catch (error) {
      throw StateError('Security Configuration Error: ${error.message}');
    }
  }

  static Uri get webSocketBaseUri {
    final uri = apiBaseUri;
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
  }

  static bool _flag(String key, String dartDefineValue) =>
      _value(key, dartDefineValue)?.toLowerCase() == 'true';

  static String? _value(String key, String dartDefineValue) {
    if (dartDefineValue.trim().isNotEmpty) return dartDefineValue;
    return dotenv.env[key];
  }
}

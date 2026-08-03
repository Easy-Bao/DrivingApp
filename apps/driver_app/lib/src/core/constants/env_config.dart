import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, staging, production }

class EnvConfig {
  EnvConfig._();

  static const AppEnvironment currentEnvironment = AppEnvironment.development;

  static const _mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
  );
  static const _driverServiceUrl = String.fromEnvironment('DRIVER_SERVICE_URL');
  static const _authServiceUrl = String.fromEnvironment('AUTH_SERVICE_URL');
  static const _tripServiceUrl = String.fromEnvironment('TRIP_SERVICE_URL');
  static const _placeServiceBaseUrl = String.fromEnvironment(
    'PLACE_SERVICE_BASE_URL',
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

  static Uri get driverServiceUri {
    return _configuredUri('DRIVER_SERVICE_URL');
  }

  static Uri get authServiceUri {
    return _configuredUri('AUTH_SERVICE_URL', fallback: 'DRIVER_SERVICE_URL');
  }

  static Uri get tripServiceUri {
    return _configuredUri('TRIP_SERVICE_URL', fallback: 'DRIVER_SERVICE_URL');
  }

  static Uri get placeServiceUri {
    return _configuredUri(
      'PLACE_SERVICE_BASE_URL',
      fallback: 'DRIVER_SERVICE_URL',
    );
  }

  static Uri get httpBaseUri => driverServiceUri;

  static Uri get webSocketBaseUri {
    final uri = httpBaseUri;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme);
  }

  static String get httpBaseUrl => httpBaseUri.toString();

  static String get webSocketBaseUrl => webSocketBaseUri.toString();

  static Uri _configuredUri(String key, {String? fallback}) {
    final rawUrl = _value(key, _dartDefine(key));
    final fallbackUrl = fallback == null
        ? null
        : _value(fallback, _dartDefine(fallback));
    final configuredUrl = rawUrl ?? fallbackUrl;
    if (configuredUrl == null || configuredUrl.trim().isEmpty) {
      throw StateError('Security Configuration Error: $key is required.');
    }
    return _resolveUri(configuredUrl);
  }

  static Uri _resolveUri(String rawUrl) {
    var uri = Uri.parse(rawUrl);
    final isPhysicalDevice =
        _value('PHYSICAL_DEVICE', _physicalDevice)?.toLowerCase() == 'true';
    if (!isPhysicalDevice && !kIsWeb && Platform.isAndroid) {
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final loopbackHost = _value(
          'ANDROID_EMULATOR_LOOPBACK_HOST',
          _androidEmulatorLoopbackHost,
        );
        if (loopbackHost == null || loopbackHost.trim().isEmpty) {
          throw StateError(
            'Security Configuration Error: '
            'ANDROID_EMULATOR_LOOPBACK_HOST is required for local Android URLs.',
          );
        }
        uri = uri.replace(host: loopbackHost);
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

  static String? _dartDefine(String key) {
    return switch (key) {
      'MAPBOX_PUBLIC_TOKEN' => _mapboxPublicToken,
      'DRIVER_SERVICE_URL' => _driverServiceUrl,
      'AUTH_SERVICE_URL' => _authServiceUrl,
      'TRIP_SERVICE_URL' => _tripServiceUrl,
      'PLACE_SERVICE_BASE_URL' => _placeServiceBaseUrl,
      'OFFLINE_MODE' => _offlineMode,
      'PHYSICAL_DEVICE' => _physicalDevice,
      'ANDROID_EMULATOR_LOOPBACK_HOST' => _androidEmulatorLoopbackHost,
      _ => null,
    };
  }
}

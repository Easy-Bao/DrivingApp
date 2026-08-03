import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, staging, production }

class EnvConfig {
  EnvConfig._();

  static const AppEnvironment currentEnvironment = AppEnvironment.development;

  static String? get mapboxPublicToken {
    final token = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    return token == null || token.isEmpty ? null : token;
  }

  static bool get offlineMode =>
      dotenv.env['OFFLINE_MODE']?.toLowerCase() == 'true';

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
    final rawUrl =
        dotenv.env[key] ?? (fallback == null ? null : dotenv.env[fallback]);
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      throw StateError('Security Configuration Error: $key is required.');
    }
    return _resolveUri(rawUrl);
  }

  static Uri _resolveUri(String rawUrl) {
    var uri = Uri.parse(rawUrl);
    final isPhysicalDevice = dotenv.env['PHYSICAL_DEVICE'] == 'true';
    if (!isPhysicalDevice && !kIsWeb && Platform.isAndroid) {
      final loopbackHost =
          dotenv.env['ANDROID_EMULATOR_LOOPBACK_HOST'] ?? '10.0.2.2';
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        uri = uri.replace(host: loopbackHost);
      }
    }
    return uri;
  }
}

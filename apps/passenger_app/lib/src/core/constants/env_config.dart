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
  static Uri get apiBaseUri => _configuredUri();
  static Uri get passengerServiceUri => apiBaseUri;
  static Uri get authServiceUri => apiBaseUri;
  static Uri get tripServiceUri => apiBaseUri;
  static Uri get placeServiceUri => apiBaseUri;
  static Uri get httpBaseUri => apiBaseUri;
  static String get httpBaseUrl => apiBaseUri.toString();

  static Uri get webSocketBaseUri {
    final uri = apiBaseUri;
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
  }

  static String get webSocketBaseUrl => webSocketBaseUri.toString();

  static Uri _configuredUri() {
    final rawUrl = dotenv.env['API_BASE_URL'];
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      throw StateError(
        'Security Configuration Error: API_BASE_URL is required.',
      );
    }
    var uri = Uri.parse(rawUrl);
    final usesAdbReverse =
        dotenv.env['ANDROID_USE_ADB_REVERSE']?.toLowerCase() != 'false';
    if (!usesAdbReverse &&
        !kIsWeb &&
        Platform.isAndroid &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      final loopbackHost = dotenv.env['ANDROID_EMULATOR_LOOPBACK_HOST'];
      if (loopbackHost == null || loopbackHost.trim().isEmpty) {
        throw StateError(
          'Security Configuration Error: ANDROID_EMULATOR_LOOPBACK_HOST is required for local Android URLs.',
        );
      }
      uri = uri.replace(host: loopbackHost);
    }
    return uri;
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, staging, production }

class EnvConfig {
  EnvConfig._();

  static const AppEnvironment currentEnvironment = AppEnvironment.development;

  static String get mapboxPublicToken {
    final token = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    if (token == null || token.isEmpty) {
      throw StateError('MAPBOX_PUBLIC_TOKEN environment variable is missing.');
    }
    return token;
  }

  static double get defaultLatitude {
    final raw = dotenv.env['DEFAULT_LATITUDE'];
    if (raw == null || raw.isEmpty) {
      return 14.5995;
    }
    return double.parse(raw);
  }

  static double get defaultLongitude {
    final raw = dotenv.env['DEFAULT_LONGITUDE'];
    if (raw == null || raw.isEmpty) {
      return 120.9842;
    }
    return double.parse(raw);
  }

  static bool get offlineMode =>
      dotenv.env['OFFLINE_MODE']?.toLowerCase() == 'true';

  static Uri get driverServiceUri {
    final rawUrl = dotenv.env['DRIVER_SERVICE_URL'] ?? 'http://localhost:8080';
    return _resolveUri(rawUrl);
  }

  static Uri get authServiceUri {
    final rawUrl = dotenv.env['AUTH_SERVICE_URL'] ??
        dotenv.env['DRIVER_SERVICE_URL'] ??
        'http://localhost:8080';
    return _resolveUri(rawUrl);
  }

  static Uri get tripServiceUri {
    final rawUrl = dotenv.env['TRIP_SERVICE_URL'] ??
        dotenv.env['DRIVER_SERVICE_URL'] ??
        'http://localhost:8080';
    return _resolveUri(rawUrl);
  }

  static Uri get placeServiceUri {
    final rawUrl = dotenv.env['PLACE_SERVICE_BASE_URL'] ??
        dotenv.env['DRIVER_SERVICE_URL'] ??
        'http://localhost:8080';
    return _resolveUri(rawUrl);
  }

  static Uri get httpBaseUri => driverServiceUri;

  static Uri get webSocketBaseUri {
    final uri = httpBaseUri;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme);
  }

  static String get httpBaseUrl => httpBaseUri.toString();

  static String get webSocketBaseUrl => webSocketBaseUri.toString();

  static Uri _resolveUri(String rawUrl) {
    var uri = Uri.parse(rawUrl);
    final isPhysicalDevice = dotenv.env['PHYSICAL_DEVICE'] == 'true';
    if (!isPhysicalDevice && !kIsWeb && Platform.isAndroid) {
      final loopbackHost = dotenv.env['ANDROID_EMULATOR_LOOPBACK_HOST'] ?? '10.0.2.2';
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        uri = uri.replace(host: loopbackHost);
      }
    }
    return uri;
  }
}

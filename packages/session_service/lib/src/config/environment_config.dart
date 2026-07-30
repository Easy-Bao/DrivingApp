import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:session_service/src/config/app_environment.dart';

class EnvironmentConfig {
  EnvironmentConfig._();

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
      throw StateError('DEFAULT_LATITUDE environment variable is missing.');
    }
    return double.parse(raw);
  }

  static double get defaultLongitude {
    final raw = dotenv.env['DEFAULT_LONGITUDE'];
    if (raw == null || raw.isEmpty) {
      throw StateError('DEFAULT_LONGITUDE environment variable is missing.');
    }
    return double.parse(raw);
  }

  static Uri get placeServiceUri {
    final rawUrl = dotenv.env['PLACE_SERVICE_BASE_URL'] ??
        dotenv.env['LOCATION_SERVICE_URL'] ??
        dotenv.env['PASSENGER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('PLACE_SERVICE_BASE_URL environment variable is missing.');
    }
    return _resolveUri(rawUrl);
  }

  static bool get offlineMode =>
      dotenv.env['OFFLINE_MODE']?.toLowerCase() == 'true';

  static Uri get driverServiceUri {
    final rawUrl = dotenv.env['DRIVER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('DRIVER_SERVICE_URL environment variable is missing.');
    }
    return _resolveUri(rawUrl);
  }

  static Uri get passengerServiceUri {
    final rawUrl = dotenv.env['PASSENGER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('PASSENGER_SERVICE_URL environment variable is missing.');
    }
    return _resolveUri(rawUrl);
  }

  static Uri get authServiceUri {
    final rawUrl = dotenv.env['AUTH_SERVICE_URL'] ??
        dotenv.env['API_GATEWAY_URL'] ??
        dotenv.env['PASSENGER_SERVICE_URL'] ??
        dotenv.env['DRIVER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('AUTH_SERVICE_URL environment variable is missing.');
    }
    return _resolveUri(rawUrl);
  }

  static Uri get tripServiceUri {
    final rawUrl =
        dotenv.env['TRIP_SERVICE_URL'] ?? dotenv.env['PASSENGER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('TRIP_SERVICE_URL environment variable is missing.');
    }
    return _resolveUri(rawUrl);
  }

  static Uri get fareServiceUri {
    final rawUrl = dotenv.env['FARE_SERVICE_URL'] ??
        dotenv.env['API_GATEWAY_URL'] ??
        dotenv.env['PASSENGER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('FARE_SERVICE_URL environment variable is missing.');
    }
    return _resolveUri(rawUrl);
  }

  static Uri get httpBaseUri {
    final uri = dotenv.env['DRIVER_SERVICE_URL'] != null
        ? driverServiceUri
        : passengerServiceUri;
    return uri;
  }

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

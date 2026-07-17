import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:session_service/src/app_environment.dart';

class EnvironmentConfig {
  EnvironmentConfig._();

  static const AppEnvironment currentEnvironment = AppEnvironment.development;

  static String get mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  static String get mapboxSecretToken =>
      dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';

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

  static Uri get tripServiceUri {
    final rawUrl =
        dotenv.env['TRIP_SERVICE_URL'] ?? dotenv.env['PASSENGER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('TRIP_SERVICE_URL environment variable is missing.');
    }
    return _resolveUri(rawUrl);
  }

  static Uri get httpBaseUri {
    final uri = dotenv.env['DRIVER_SERVICE_URL'] != null
        ? driverServiceUri
        : passengerServiceUri;
    if (uri.port == 8081 || uri.port == 8082 || uri.port == 8083) {
      return uri.replace(port: 8080);
    }
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
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        uri = uri.replace(host: '10.0.2.2');
      }
    }
    return uri;
  }
}

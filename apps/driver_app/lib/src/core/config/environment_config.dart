import 'dart:io';
import 'package:driver_app/src/core/config/app_environment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment and service configuration for the Driver App.
///
/// Loads tokens and API/WebSocket URIs directly from application environment
/// variables using Dart's native [Uri] class to structure endpoints.
class EnvironmentConfig {
  EnvironmentConfig._();

  /// The active execution environment mode.
  static const AppEnvironment currentEnvironment = AppEnvironment.development;

  /// Retrieves the public Mapbox API access token.
  static String get mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  /// Retrieves the secret Mapbox API access token.
  static String get mapboxSecretToken =>
      dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';

  /// Flag indicating if the application runs in offline simulation mode.
  static bool get offlineMode =>
      dotenv.env['OFFLINE_MODE']?.toLowerCase() == 'true';

  /// Resolves and builds the base driver service URI from the environment.
  static Uri get driverServiceUri {
    final rawUrl = dotenv.env['DRIVER_SERVICE_URL'];
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError(
        'DRIVER_SERVICE_URL environment variable is missing or empty.',
      );
    }
    return _resolveUri(rawUrl);
  }

  /// Resolves the gateway/base service HTTP endpoint.
  ///
  /// Automatically remaps specific microservice ports (e.g., 8081, 8082, 8083) to
  /// the unified gateway port 8080.
  static Uri get httpBaseUri {
    final uri = driverServiceUri;
    if (uri.port == 8081 || uri.port == 8082 || uri.port == 8083) {
      return uri.replace(port: 8080);
    }
    return uri;
  }

  /// Resolves the WebSocket communication endpoint.
  ///
  /// Inherits base connection parameters from [httpBaseUri] and swaps the scheme to
  /// 'ws' or 'wss' dynamically.
  static Uri get webSocketBaseUri {
    final uri = httpBaseUri;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme);
  }

  /// Returns the base service HTTP URL as a string.
  static String get httpBaseUrl => httpBaseUri.toString();

  /// Returns the WebSocket base URL as a string.
  static String get webSocketBaseUrl => webSocketBaseUri.toString();

  /// Retrieves the Sentry DSN for crash reporting initialization.
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';

  /// Swaps loopback hosts to the Android emulator interface address (10.0.2.2)
  /// when running on an Android Virtual Device.
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

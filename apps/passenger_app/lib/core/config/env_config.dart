import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration.
/// Wraps flutter_dotenv for type-safe access to env variables.
class EnvConfig {
  EnvConfig._();

  static String get mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  static String get mapboxSecretToken =>
      dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';

  static String get passengerServiceUrl {
    final baseUrl = dotenv.env['PASSENGER_SERVICE_URL'] ?? null;
    if (!kIsWeb && Platform.isAndroid && baseUrl.contains('localhost')) {
      return baseUrl.replaceAll('localhost', '10.0.2.2');
    }
    return baseUrl;
  }
}

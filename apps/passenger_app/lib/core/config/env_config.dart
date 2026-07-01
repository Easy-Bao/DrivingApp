import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  static String get mapboxSecretToken =>
      dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';

  static String? get passengerServiceUrl {
    final baseUrl = dotenv.env['PASSENGER_SERVICE_URL'];
    if (!kIsWeb && Platform.isAndroid && baseUrl!.contains('localhost')) {
      return baseUrl.replaceAll('localhost', '10.0.2.2');
    }
    return baseUrl;
  }

  /// The base URL for the trip-service (ride lifecycle management).
  /// On Android emulator, localhost is automatically remapped to 10.0.2.2.
  static String? get tripServiceUrl {
    final baseUrl = dotenv.env['TRIP_SERVICE_URL'];
    if (baseUrl == null) return null;
    if (!kIsWeb && Platform.isAndroid && baseUrl.contains('localhost')) {
      return baseUrl.replaceAll('localhost', '10.0.2.2');
    }
    return baseUrl;
  }
}


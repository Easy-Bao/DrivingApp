import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  static String get mapboxSecretToken =>
      dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';

  static String? get passengerServiceUrl =>
      _resolveEmulatorHost(dotenv.env['PASSENGER_SERVICE_URL']);

  static String? get tripServiceUrl =>
      _resolveEmulatorHost(dotenv.env['TRIP_SERVICE_URL']);

  static String? _resolveEmulatorHost(String? url) {
    if (url == null) return null;
    final isPhysicalDevice = dotenv.env['PHYSICAL_DEVICE'] == 'true';
    if (!isPhysicalDevice && !kIsWeb && Platform.isAndroid) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }
}


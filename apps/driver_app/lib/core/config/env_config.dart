/// Centralized environment configuration for driver_app resolving Android localhost emulation.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  static String get mapboxSecretToken =>
      dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';

  static String get driverServiceUrl {
    final baseUrl = dotenv.env['DRIVER_SERVICE_URL'] ?? 'http://127.0.0.1:8080';
    final isPhysicalDevice = dotenv.env['PHYSICAL_DEVICE'] == 'true';
    if (!isPhysicalDevice &&
        !kIsWeb &&
        Platform.isAndroid &&
        baseUrl.contains('localhost')) {
      return baseUrl.replaceAll('localhost', '10.0.2.2');
    }
    if (!isPhysicalDevice &&
        !kIsWeb &&
        Platform.isAndroid &&
        baseUrl.contains('127.0.0.1')) {
      return baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return baseUrl;
  }

  static bool get offlineMode =>
      dotenv.env['OFFLINE_MODE']?.toLowerCase() == 'true';
}

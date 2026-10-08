import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foundation/foundation.dart';

class DriverEnvConfig._() {
  static const _buildValues = <String, String>{
    'APP_ENV': String.fromEnvironment('APP_ENV'),
    'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
    'MAPBOX_PUBLIC_TOKEN': String.fromEnvironment('MAPBOX_PUBLIC_TOKEN'),
    'SENTRY_DSN': String.fromEnvironment('SENTRY_DSN'),
    'PHYSICAL_DEVICE': String.fromEnvironment('PHYSICAL_DEVICE'),
    'ANDROID_USE_ADB_REVERSE': String.fromEnvironment(
      'ANDROID_USE_ADB_REVERSE',
    ),
    'ANDROID_EMULATOR_LOOPBACK_HOST': String.fromEnvironment(
      'ANDROID_EMULATOR_LOOPBACK_HOST',
    ),
    'ENABLE_DRIVER_BACKGROUND_TELEMETRY': String.fromEnvironment(
      'ENABLE_DRIVER_BACKGROUND_TELEMETRY',
    ),
  };

  static ClientEnvironment get _config => ClientEnvironment(
    environment: dotenv.env,
    buildValues: _buildValues,
    allowInsecureHttp: !kReleaseMode,
    isAndroid: !kIsWeb && Platform.isAndroid,
  );

  static String? get mapboxPublicToken => _config.mapboxPublicToken;

  static String get appEnvironment => _config.appEnvironment;

  static String get sentryDsn => _config.sentryDsn;

  static bool get backgroundTelemetryEnabled =>
      _config.flag('ENABLE_DRIVER_BACKGROUND_TELEMETRY', defaultValue: true);

  static Uri get apiBaseUri => _config.apiBaseUri;

  static Uri get webSocketBaseUri => _config.webSocketBaseUri;
}

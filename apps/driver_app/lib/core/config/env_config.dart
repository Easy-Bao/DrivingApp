import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration.
/// Wraps flutter_dotenv for type-safe access to env variables.
class EnvConfig {
  EnvConfig._();

  static String get mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  static String get mapboxSecretToken =>
      dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';
}

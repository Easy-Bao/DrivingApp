import '../network/api_base_uri.dart';

/// Resolves public client configuration without owning an environment file.
///
/// Applications provide the values loaded from their own bundled `.env` asset
/// and any build-time `--dart-define` overrides. Keeping the source outside
/// this package lets the shared package remain reusable by Passenger, Driver,
/// and tests.
class ClientEnvironment {
  ClientEnvironment({
    required this.environment,
    required this.buildValues,
    required this.allowInsecureHttp,
    required this.isAndroid,
  });

  final Map<String, String> environment;
  final Map<String, String> buildValues;
  final bool allowInsecureHttp;
  final bool isAndroid;

  String? get mapboxPublicToken {
    final token = value('MAPBOX_PUBLIC_TOKEN')?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  String get appEnvironment {
    final configured = value('APP_ENV')?.trim();
    return configured == null || configured.isEmpty
        ? 'development'
        : configured;
  }

  String get sentryDsn => value('SENTRY_DSN') ?? '';

  bool get isPhysicalDevice => flag('PHYSICAL_DEVICE');

  bool get usesAdbReverse => flag('ANDROID_USE_ADB_REVERSE');

  Uri get apiBaseUri {
    final rawUrl = value('API_BASE_URL');
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      throw StateError(
        'Security Configuration Error: API_BASE_URL is required.',
      );
    }

    try {
      return resolveMobileApiBaseUri(
        rawUrl: rawUrl,
        allowInsecureHttp: allowInsecureHttp,
        isAndroid: isAndroid,
        isPhysicalDevice: isPhysicalDevice,
        usesAdbReverse: usesAdbReverse,
        androidEmulatorLoopbackHost: value('ANDROID_EMULATOR_LOOPBACK_HOST'),
      );
    } on FormatException catch (error) {
      throw StateError('Security Configuration Error: ${error.message}');
    }
  }

  Uri get webSocketBaseUri {
    final uri = apiBaseUri;
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
  }

  bool flag(String key, {bool defaultValue = false}) {
    final configured = value(key);
    if (configured == null || configured.trim().isEmpty) {
      return defaultValue;
    }
    return configured.trim().toLowerCase() == 'true';
  }

  String? value(String key) {
    final buildValue = buildValues[key];
    if (buildValue != null && buildValue.trim().isNotEmpty) {
      return buildValue;
    }
    return environment[key];
  }
}

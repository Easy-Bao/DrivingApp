import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('build-time values take precedence over bundled values', () {
    final config = ClientEnvironment(
      environment: const {
        'APP_ENV': 'development',
        'API_BASE_URL': 'http://127.0.0.1:8000',
      },
      buildValues: const {
        'APP_ENV': 'staging',
        'API_BASE_URL': 'https://api.example.test',
      },
      allowInsecureHttp: true,
      isAndroid: false,
    );

    expect(config.appEnvironment, 'staging');
    expect(config.apiBaseUri.toString(), 'https://api.example.test');
  });

  test('resolves optional flags and Android loopback through one contract', () {
    final config = ClientEnvironment(
      environment: const {
        'API_BASE_URL': 'http://127.0.0.1:8123',
        'PHYSICAL_DEVICE': 'false',
        'ANDROID_USE_ADB_REVERSE': 'false',
        'ANDROID_EMULATOR_LOOPBACK_HOST': '10.0.3.2',
        'ENABLE_DRIVER_BACKGROUND_TELEMETRY': 'false',
      },
      buildValues: const {},
      allowInsecureHttp: true,
      isAndroid: true,
    );

    expect(config.apiBaseUri.toString(), 'http://10.0.3.2:8123');
    expect(config.flag('ENABLE_DRIVER_BACKGROUND_TELEMETRY'), isFalse);
    expect(config.flag('UNKNOWN_FLAG', defaultValue: true), isTrue);
  });

  test('rejects a missing API base URL with an actionable error', () {
    final missingEnvConfig = ClientEnvironment(
      environment: const {},
      buildValues: const {},
      allowInsecureHttp: true,
      isAndroid: false,
    );

    expect(
      () => missingEnvConfig.apiBaseUri,
      throwsA(
        isA<ConfigurationException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('API_BASE_URL is required'),
            contains('no .env entries were loaded'),
          ),
        ),
      ),
    );

    final loadedEnvWithoutUrl = ClientEnvironment(
      environment: const {'APP_ENV': 'development'},
      buildValues: const {},
      allowInsecureHttp: true,
      isAndroid: false,
    );

    expect(
      () => loadedEnvWithoutUrl.apiBaseUri,
      throwsA(
        isA<ConfigurationException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('API_BASE_URL is required'),
            isNot(contains('no .env entries were loaded')),
          ),
        ),
      ),
    );
  });

  test('names the offending key for invalid API URL or loopback host', () {
    final insecureRelease = ClientEnvironment(
      environment: const {'API_BASE_URL': 'http://api.example.test'},
      buildValues: const {},
      allowInsecureHttp: false,
      isAndroid: false,
    );
    expect(
      () => insecureRelease.apiBaseUri,
      throwsA(
        isA<ConfigurationException>().having(
          (error) => error.message,
          'message',
          contains('HTTPS'),
        ),
      ),
    );

    final invalidLoopback = ClientEnvironment(
      environment: const {
        'API_BASE_URL': 'http://localhost:8000',
        'ANDROID_EMULATOR_LOOPBACK_HOST': 'bad host/path',
      },
      buildValues: const {},
      allowInsecureHttp: true,
      isAndroid: true,
    );
    expect(
      () => invalidLoopback.apiBaseUri,
      throwsA(
        isA<ConfigurationException>().having(
          (error) => error.message,
          'message',
          contains('ANDROID_EMULATOR_LOOPBACK_HOST'),
        ),
      ),
    );
  });
}

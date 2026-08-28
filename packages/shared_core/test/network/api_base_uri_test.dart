import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('normalizes an origin-only API base URL', () {
    final uri = parseApiBaseUri(' https://api.example.test:8443/ ');

    expect(uri.toString(), 'https://api.example.test:8443');
  });

  test('rejects API URLs that can redirect requests or carry credentials', () {
    for (final value in [
      '',
      'api.example.test',
      'ftp://api.example.test',
      'https://api.example.test/gateway',
      'https://api.example.test?redirect=elsewhere',
      'https://user:password@api.example.test',
      'http://0.0.0.0:8000',
      'http://[::]:8000',
      'http://*:8000',
    ]) {
      expect(
        () => parseApiBaseUri(value),
        throwsA(isA<FormatException>()),
        reason: 'Expected $value to be rejected',
      );
    }
  });

  test('requires HTTPS when insecure transport is disabled', () {
    expect(
      () =>
          parseApiBaseUri('http://api.example.test', allowInsecureHttp: false),
      throwsA(isA<FormatException>()),
    );
    expect(
      parseApiBaseUri(
        'https://api.example.test',
        allowInsecureHttp: false,
      ).toString(),
      'https://api.example.test',
    );
  });

  test('rewrites local Android origins only for emulator networking', () {
    final emulatorUri = resolveMobileApiBaseUri(
      rawUrl: 'http://127.0.0.1:8123',
      allowInsecureHttp: true,
      isAndroid: true,
      isPhysicalDevice: false,
      usesAdbReverse: false,
      androidEmulatorLoopbackHost: '10.0.2.2',
    );
    final adbReverseUri = resolveMobileApiBaseUri(
      rawUrl: 'http://127.0.0.1:8123',
      allowInsecureHttp: true,
      isAndroid: true,
      isPhysicalDevice: false,
      usesAdbReverse: true,
    );

    expect(emulatorUri.toString(), 'http://10.0.2.2:8123');
    expect(adbReverseUri.toString(), 'http://127.0.0.1:8123');
  });

  test('requires an explicit Android emulator loopback host', () {
    expect(
      () => resolveMobileApiBaseUri(
        rawUrl: 'http://localhost:8123',
        allowInsecureHttp: true,
        isAndroid: true,
        isPhysicalDevice: false,
        usesAdbReverse: false,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

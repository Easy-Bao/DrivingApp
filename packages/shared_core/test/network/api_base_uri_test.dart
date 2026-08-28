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
}

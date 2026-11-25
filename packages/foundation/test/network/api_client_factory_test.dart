import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

final class _MemoryTokenStore implements SessionTokenStore {
  String? token = 'access-1';
  String? refreshToken = 'refresh-1';

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> saveRefreshToken(String value) async => refreshToken = value;

  @override
  Future<void> clearSession() async {
    token = null;
    refreshToken = null;
  }
}

void main() {
  test('ApiClientFactory wires shared interceptors and configure hook', () {
    final store = _MemoryTokenStore();
    final availability = NetworkAvailabilityCoordinator();
    var configured = false;
    final dio = ApiClientFactory.create(
      baseUrl: Uri.parse('https://api.example.test'),
      sessionStore: store,
      networkAvailability: availability,
      enableMetrics: true,
      enableDebugLogging: true,
      configureDio: (_) => configured = true,
    );
    addTearDown(() async {
      dio.close(force: true);
      await availability.dispose();
    });

    expect(configured, isTrue);
    expect(dio.interceptors.whereType<BearerAuthInterceptor>(), hasLength(1));
    expect(
      dio.interceptors.whereType<RequestMetricsInterceptor>(),
      hasLength(1),
    );
    expect(dio.interceptors.whereType<LoggingInterceptor>(), hasLength(1));
    expect(dio.interceptors.whereType<IdempotencyInterceptor>(), hasLength(1));
    expect(
      dio.interceptors.whereType<NetworkAvailabilityInterceptor>(),
      hasLength(1),
    );
    expect(dio.interceptors.whereType<RetryInterceptor>(), hasLength(1));
  });
}

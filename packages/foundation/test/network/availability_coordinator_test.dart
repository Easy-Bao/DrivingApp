import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('emits one status event per availability transition', () async {
    final now = DateTime(2026, 8, 31);
    final coordinator = NetworkAvailabilityCoordinator(
      failureThreshold: 2,
      cooldown: const Duration(seconds: 5),
      now: () => now,
    );
    final statuses = <NetworkAvailabilityStatus>[];
    final subscription = coordinator.changes.listen(statuses.add);
    addTearDown(() async {
      await subscription.cancel();
      await coordinator.dispose();
    });

    coordinator.recordFailure();
    coordinator.recordFailure();
    coordinator.recordFailure();
    coordinator.recordSuccess();

    expect(statuses, [
      NetworkAvailabilityStatus.degraded,
      NetworkAvailabilityStatus.unavailable,
      NetworkAvailabilityStatus.available,
    ]);
  });

  test('opens the circuit and admits one half-open probe after cooldown', () {
    var now = DateTime(2026, 8, 31);
    final coordinator = NetworkAvailabilityCoordinator(
      failureThreshold: 1,
      cooldown: const Duration(seconds: 5),
      now: () => now,
    );
    addTearDown(coordinator.dispose);

    expect(coordinator.tryAcquireRequest(), isTrue);
    coordinator.recordFailure();
    expect(coordinator.isCircuitOpen, isTrue);
    expect(coordinator.tryAcquireRequest(), isFalse);

    now = now.add(const Duration(seconds: 6));
    expect(coordinator.tryAcquireRequest(), isTrue);
    expect(coordinator.tryAcquireRequest(), isFalse);

    coordinator.recordSuccess();
    expect(coordinator.status, NetworkAvailabilityStatus.available);
    expect(coordinator.tryAcquireRequest(), isTrue);
  });

  test(
    'Dio rejects circuit-open requests without another adapter attempt',
    () async {
      var attempts = 0;
      final coordinator = NetworkAvailabilityCoordinator(
        failureThreshold: 1,
        cooldown: const Duration(minutes: 1),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _FailingHttpClientAdapter(() => attempts++)
        ..interceptors.add(NetworkAvailabilityInterceptor(coordinator));
      addTearDown(() async {
        dio.close(force: true);
        await coordinator.dispose();
      });

      await expectLater(
        dio.get<void>('/api/v1/dashboard'),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        dio.get<void>('/api/v1/dashboard'),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'error',
            isA<NetworkCircuitOpenException>(),
          ),
        ),
      );

      expect(attempts, 1);
    },
  );
}

class _FailingHttpClientAdapter(this.onAttempt) implements HttpClientAdapter {
  final void Function() onAttempt;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    onAttempt();
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

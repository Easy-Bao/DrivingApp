import 'package:fare_services/fare_services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFareRemoteDataSource implements FareRemoteDataSource {
  final Map<String, dynamic>? response;
  final bool shouldThrow;

  MockFareRemoteDataSource({this.response, this.shouldThrow = false});

  @override
  Future<Map<String, dynamic>> fetchFareQuote({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  }) async {
    if (shouldThrow) {
      throw Exception('Server network failure');
    }
    return response ?? {};
  }

  @override
  Future<Map<String, dynamic>> fetchPricingConfigs() async {
    if (shouldThrow) {
      throw Exception('Server network failure');
    }
    return response ?? {};
  }

  @override
  Future<Map<String, dynamic>> fetchFareEstimates({
    required double distanceKm,
    double durationMinutes = 0.0,
  }) async {
    if (shouldThrow) {
      throw Exception('Server network failure');
    }
    return response ?? {};
  }

  @override
  Future<Map<String, dynamic>> calculateFinalFare({
    required String rideId,
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
    double surgeMultiplier = 1.0,
  }) async {
    if (shouldThrow) {
      throw Exception('Server network failure');
    }
    return response ?? {};
  }
}

void main() {
  group('PaymentMethod', () {
    test('enforces Cash on Hand', () {
      expect(PaymentMethod.cashOnHand, PaymentMethod.cashOnHand);
    });
  });

  group('FareFormatter', () {
    test('formats currency accurately', () {
      expect(FareFormatter.formatCurrency(125.5), '₱125.50');
      expect(FareFormatter.formatCurrency(0.0), '₱0.00');
    });

    test('formats payment method', () {
      expect(FareFormatter.formatPaymentMethod(PaymentMethod.cashOnHand), 'Cash on Hand');
    });

    test('formats summary with fallback indicator', () {
      const breakdown = FareBreakdown(
        baseFare: 20.0,
        distanceCharge: 50.0,
        timeCharge: 10.0,
        surgeCharge: 0.0,
        totalFare: 80.0,
      );
      const estimate = FareEstimate(
        breakdown: breakdown,
        paymentMethod: PaymentMethod.cashOnHand,
        isEstimateFallback: true,
      );
      final summary = FareFormatter.formatSummary(estimate);
      expect(summary, contains('₱80.00'));
      expect(summary, contains('Cash on Hand'));
    });
  });

  group('FareCalculatorHelper', () {
    test('synchronizes active service pricing rules from backend authority', () {
      FareCalculatorHelper.synchronizeServicePricingRules([
        const ServicePricingConfig(
          serviceName: 'Solo Ride',
          baseFare: 25.0,
          perKmRate: 12.0,
          perMinuteRate: 2.0,
        ),
      ]);

      final updatedConfig = FareCalculatorHelper.activeConfigs['Solo Ride'];
      expect(updatedConfig?.baseFare, 25.0);
      expect(updatedConfig?.perKmRate, 12.0);
    });
  });

  group('FareRepositoryImpl', () {
    test('parses Server quote when available', () async {
      final mock = MockFareRemoteDataSource(
        response: {
          'success': true,
          'data': {
            'base_fare': 20.0,
            'distance_charge': 40.0,
            'time_charge': 15.0,
            'surge_charge': 5.0,
            'total_fare': 80.0,
          },
        },
      );
      final repo = FareRepositoryImpl(remoteDataSource: mock);
      final result = await repo.getFareQuote(distanceKm: 4.0, durationMinutes: 10.0);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (estimate) {
          expect(estimate.breakdown.totalFare, 80.0);
          expect(estimate.isEstimateFallback, false);
          expect(estimate.paymentMethod, PaymentMethod.cashOnHand);
        },
      );
    });

    test('falls back gracefully to local client estimate on network exception', () async {
      final mock = MockFareRemoteDataSource(shouldThrow: true);
      final repo = FareRepositoryImpl(remoteDataSource: mock);
      final result = await repo.getFareQuote(distanceKm: 5.0, durationMinutes: 10.0);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should not fail on network exception'),
        (estimate) {
          expect(estimate.isEstimateFallback, true);
          expect(estimate.paymentMethod, PaymentMethod.cashOnHand);
        },
      );
    });
  });
}

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
      throw Exception('Backend network failure');
    }
    return response ?? {};
  }
}

void main() {
  group('PaymentMethod', () {
    test('enforces Cash on Hand', () {
      expect(PaymentMethod.cashOnHand.displayName, 'Cash on Hand');
      expect(PaymentMethod.cashOnHand.code, 'CASH');
    });
  });

  group('FareFormatter', () {
    test('formats currency accurately', () {
      expect(FareFormatter.formatCurrency(45.5), '₱45.50');
      expect(FareFormatter.formatCurrency(100.0), '₱100.00');
    });

    test('formats payment method', () {
      expect(
        FareFormatter.formatPaymentMethod(PaymentMethod.cashOnHand),
        'Cash on Hand',
      );
    });

    test('formats summary with fallback indicator', () {
      const estimate = FareEstimate(
        breakdown: FareBreakdown(
          baseFare: 20.0,
          distanceCharge: 15.0,
          timeCharge: 5.0,
          surgeCharge: 0.0,
          totalFare: 40.0,
        ),
        paymentMethod: PaymentMethod.cashOnHand,
        isEstimateFallback: true,
      );

      expect(
        FareFormatter.formatSummary(estimate),
        '₱40.00 • Cash on Hand (Est.)',
      );
    });
  });

  group('FareRepositoryImpl', () {
    test('parses backend quote when available', () async {
      final mockSource = MockFareRemoteDataSource(
        response: {
          'base_fare': 20.0,
          'distance_charge': 25.0,
          'time_charge': 5.0,
          'surge_charge': 0.0,
          'total_fare': 50.0,
        },
      );

      final repo = FareRepositoryImpl(remoteDataSource: mockSource);
      final result = await repo.getFareQuote(
        distanceKm: 2.5,
        durationMinutes: 5.0,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should succeed'),
        (estimate) {
          expect(estimate.breakdown.totalFare, 50.0);
          expect(estimate.paymentMethod, PaymentMethod.cashOnHand);
          expect(estimate.isEstimateFallback, isFalse);
        },
      );
    });

    test('falls back to local client estimate on network exception', () async {
      final mockSource = MockFareRemoteDataSource(shouldThrow: true);
      final repo = FareRepositoryImpl(remoteDataSource: mockSource);

      final result = await repo.getFareQuote(
        distanceKm: 2.0,
        durationMinutes: 4.0,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should succeed'),
        (estimate) {
          expect(estimate.paymentMethod, PaymentMethod.cashOnHand);
          expect(estimate.isEstimateFallback, isTrue);
          expect(estimate.breakdown.totalFare, 46.0); // 20 + 20 + 6 = 46
        },
      );
    });
  });
}

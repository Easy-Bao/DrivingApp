import 'package:fare_services/src/features/fare/domain/entities/fare_estimate.dart';
import 'package:fare_services/src/features/fare/domain/entities/payment_method.dart';

class FareFormatter {
  FareFormatter._();

  static String formatCurrency(double amount, {String symbol = '₱'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatPaymentMethod(PaymentMethod method) {
    return method.displayName;
  }

  static String formatSummary(FareEstimate estimate) {
    final formattedFare = formatCurrency(estimate.breakdown.totalFare);
    final fallbackIndicator = estimate.isEstimateFallback ? ' (Est.)' : '';
    return '$formattedFare • ${estimate.paymentMethod.displayName}$fallbackIndicator';
  }
}

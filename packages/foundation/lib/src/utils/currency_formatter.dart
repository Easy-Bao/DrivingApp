/// Formats a peso amount for client-facing fare and earnings labels.
///
/// Monetary values remain minor-unit accurate in transport and domain models;
/// this formatter applies comma thousands separators and standard two-decimal
/// centavo precision.
String formatPesoAmount(num amount) {
  if (!amount.isFinite) return '₱—';

  final isNegative = amount < 0;
  final absAmount = amount.abs();
  final fixedStr = absAmount.toStringAsFixed(2);
  final parts = fixedStr.split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();
  final len = integerPart.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(integerPart[i]);
  }

  final formatted = '$buffer.$decimalPart';
  if (isNegative && absAmount >= 0.005) {
    return '-₱$formatted';
  }
  return '₱$formatted';
}

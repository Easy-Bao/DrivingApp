/// Formats a peso amount for client-facing fare and earnings labels.
///
/// Monetary values remain minor-unit accurate in transport and domain models;
/// this formatter applies comma thousands separators and standard two-decimal
/// centavo precision.
String formatPesoAmount(num amount) {
  if (!amount.isFinite) return '₱—';

  final isNegative = amount < 0;
  final absoluteAmount = amount.abs();
  final fixedString = absoluteAmount.toStringAsFixed(2);
  final parts = fixedString.split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();
  final length = integerPart.length;
  for (int index = 0; index < length; index++) {
    if (index > 0 && (length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(integerPart[index]);
  }

  final formatted = '$buffer.$decimalPart';
  if (isNegative && absoluteAmount >= 0.005) {
    return '-₱$formatted';
  }
  return '₱$formatted';
}

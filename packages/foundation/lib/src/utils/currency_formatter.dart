/// Formats a peso amount for client-facing fare and earnings labels.
///
/// Monetary values remain minor-unit accurate in transport and domain models;
/// this formatter only controls the compact whole-peso presentation.
String formatPesoAmount(num amount) {
  if (!amount.isFinite) return '₱—';
  final rounded = amount.round();
  if (rounded < 0) {
    return '-₱${rounded.abs()}';
  }
  return '₱$rounded';
}

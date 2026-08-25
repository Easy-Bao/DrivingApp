/// Formats a peso amount for client-facing fare and earnings labels.
///
/// Monetary values remain centavo-accurate in transport and domain models;
/// this formatter only controls the compact whole-peso presentation.
String formatPesoAmount(num amount) {
  if (!amount.isFinite) return '₱—';
  return '₱${amount.round()}';
}

class NumberFormatter {
  static String formatCurrency(double amount) => '₱${amount.toStringAsFixed(2)}';
  static String formatDistance(double distanceKm) => '${distanceKm.toStringAsFixed(1)} km';
}

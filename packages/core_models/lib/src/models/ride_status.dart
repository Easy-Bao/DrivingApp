/// Defines the state transitions of a passenger trip/ride request lifecycle.
enum RideStatus {
  /// The ride request has been created and is waiting for driver bidding or acceptance.
  requested('requested'),

  /// A driver accepted or bid on the ride and is now assigned.
  accepted('accepted'),

  /// The driver has arrived at the pickup location.
  arrived('arrived'),

  /// The ride is active and passenger is in transit to destination.
  inTransit('in_transit'),

  /// The ride was completed successfully.
  completed('completed'),

  /// The ride request was cancelled by either the passenger or the driver.
  cancelled('cancelled'),

  /// An unrecognized status returned by fallback or external network channels.
  unknown('unknown');

  /// The raw string value matching backend database entries.
  final String value;

  const RideStatus(this.value);

  /// Resolves the corresponding type-safe [RideStatus] from a backend string representation.
  /// Handles spelling variances like 'canceled' and maps them to [RideStatus.cancelled],
  /// and 'in_progress' to [RideStatus.inTransit].
  static RideStatus fromString(String statusStr) {
    final normalized = statusStr.toLowerCase().trim();
    if (normalized == 'canceled') {
      return RideStatus.cancelled;
    }
    if (normalized == 'in_progress') {
      return RideStatus.inTransit;
    }
    return RideStatus.values.firstWhere(
      (element) => element.value.toLowerCase() == normalized,
      orElse: () => RideStatus.unknown,
    );
  }
}

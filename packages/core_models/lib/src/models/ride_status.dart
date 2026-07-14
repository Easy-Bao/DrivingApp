/// State transitions defining the passenger trip request lifecycle.
enum RideStatus {
  requested('requested'),
  accepted('accepted'),
  arrived('arrived'),
  inTransit('in_transit'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('unknown');

  final String value;

  const RideStatus(this.value);

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

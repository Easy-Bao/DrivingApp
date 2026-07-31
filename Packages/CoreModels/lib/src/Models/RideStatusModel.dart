import 'package:json_annotation/json_annotation.dart';

enum RideStatus {
  requested('requested'),
  accepted('accepted'),
  arrived('arrived'),
  @JsonValue('in_transit')
  inTransit('in_transit'),
  completed('completed'),
  @JsonValue('canceled')
  cancelled('canceled'),
  unknown('unknown');

  final String value;

  const RideStatus(this.value);

  static RideStatus fromString(String statusStr) {
    final normalized = statusStr.toLowerCase().trim();
    if (normalized == 'cancelled') {
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

class DistanceFormatter._() {
  static String fromKilometers(
    num? distanceInKilometers, {
    String unavailableLabel = '—',
  }) {
    final distance = distanceInKilometers?.toDouble();
    if (distance == null || !distance.isFinite || distance < 0) {
      return unavailableLabel;
    }

    if (distance < 1) {
      final meters = (distance * 1000).round();
      if (meters < 1000) {
        return '$meters m';
      }
      return '1 km';
    }

    final roundedDistance = distance.toStringAsFixed(1);
    final readableDistance = roundedDistance.endsWith('.0')
        ? roundedDistance.substring(0, roundedDistance.length - 2)
        : roundedDistance;
    return '$readableDistance km';
  }
}

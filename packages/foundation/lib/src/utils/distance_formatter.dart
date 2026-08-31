class DistanceFormatter {
  DistanceFormatter._();

  static String fromKilometers(
    num? distanceInKilometers, {
    String unavailableLabel = '—',
  }) {
    final distance = distanceInKilometers?.toDouble();
    if (distance == null || !distance.isFinite || distance < 0) {
      return unavailableLabel;
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    final roundedDistance = distance.toStringAsFixed(1);
    final readableDistance = roundedDistance.endsWith('.0')
        ? roundedDistance.substring(0, roundedDistance.length - 2)
        : roundedDistance;
    return '$readableDistance km';
  }
}

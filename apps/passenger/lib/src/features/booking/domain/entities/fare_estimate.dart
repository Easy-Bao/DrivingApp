import 'package:equatable/equatable.dart';

class const FareEstimate({
  required this.baseFare,
  required this.distanceCharge,
  required this.timeCharge,
  required this.surgeCharge,
  required this.totalFare,
}) extends Equatable {
  final double baseFare;
  final double distanceCharge;
  final double timeCharge;
  final double surgeCharge;
  final double totalFare;

  factory fromJson(Map<String, dynamic> json) {
    final {
      'base_fare': rawBaseFare,
      'distance_charge': rawDistanceCharge,
      'time_charge': rawTimeCharge,
      'surge_charge': rawSurgeCharge,
      'total_fare': rawTotalFare,
    } = _canonicalPayload(
      json,
    );

    return FareEstimate(
      baseFare: _requiredNumber(rawBaseFare, 'base_fare'),
      distanceCharge: _requiredNumber(rawDistanceCharge, 'distance_charge'),
      timeCharge: _requiredNumber(rawTimeCharge, 'time_charge'),
      surgeCharge: _requiredNumber(rawSurgeCharge, 'surge_charge'),
      totalFare: _requiredNumber(rawTotalFare, 'total_fare'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_fare': baseFare,
      'distance_charge': distanceCharge,
      'time_charge': timeCharge,
      'surge_charge': surgeCharge,
      'total_fare': totalFare,
    };
  }

  @override
  List<Object?> get props => [
    baseFare,
    distanceCharge,
    timeCharge,
    surgeCharge,
    totalFare,
  ];
}

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'base_fare': json['base_fare'],
  'distance_charge': json['distance_charge'],
  'time_charge': json['time_charge'],
  'surge_charge': json['surge_charge'],
  'total_fare': json['total_fare'],
};

double _requiredNumber(Object? value, String key) {
  return switch (value) {
    final num amount => amount.toDouble(),
    _ => throw FormatException('Missing numeric fare result: $key'),
  };
}

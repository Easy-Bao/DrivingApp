import 'package:equatable/equatable.dart';

class FareResult extends Equatable {
  final double baseFare;
  final double distanceCharge;
  final double timeCharge;
  final double surgeCharge;
  final double totalFare;

  const FareResult({
    required this.baseFare,
    required this.distanceCharge,
    required this.timeCharge,
    required this.surgeCharge,
    required this.totalFare,
  });

  factory FareResult.fromJson(Map<String, dynamic> json) {
    return FareResult(
      baseFare: _requiredNumber(json, 'base_fare'),
      distanceCharge: _requiredNumber(json, 'distance_charge'),
      timeCharge: _requiredNumber(json, 'time_charge'),
      surgeCharge: _requiredNumber(json, 'surge_charge'),
      totalFare: _requiredNumber(json, 'total_fare'),
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

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Missing numeric fare result: $key');
  }
  return value.toDouble();
}

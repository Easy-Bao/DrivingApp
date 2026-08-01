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
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0.0,
      distanceCharge: (json['distance_charge'] as num?)?.toDouble() ?? 0.0,
      timeCharge: (json['time_charge'] as num?)?.toDouble() ?? 0.0,
      surgeCharge: (json['surge_charge'] as num?)?.toDouble() ?? 0.0,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
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

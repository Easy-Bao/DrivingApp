import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/FareResultModel.g.dart';

@JsonSerializable()
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

  factory FareResult.fromJson(Map<String, dynamic> json) =>
      _$FareResultFromJson(json);

  Map<String, dynamic> toJson() => _$FareResultToJson(this);

  @override
  List<Object?> get props => [
        baseFare,
        distanceCharge,
        timeCharge,
        surgeCharge,
        totalFare,
      ];
}


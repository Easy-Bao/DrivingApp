import 'package:equatable/equatable.dart';

class const PublicDriverSummary({
  required this.id,
  required this.name,
  required this.vehicleType,
  required this.rating,
}) extends Equatable {
  final String id;
  final String name;
  final String vehicleType;
  final double rating;

  @override
  List<Object?> get props => [id, name, vehicleType, rating];
}

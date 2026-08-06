import 'package:equatable/equatable.dart';

class PublicDriverSummary extends Equatable {
  final String id;
  final String name;
  final String vehicleType;
  final double rating;

  const PublicDriverSummary({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.rating,
  });

  @override
  List<Object?> get props => [id, name, vehicleType, rating];
}

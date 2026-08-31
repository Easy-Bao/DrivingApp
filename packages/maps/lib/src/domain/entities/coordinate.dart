import 'package:equatable/equatable.dart';

class Coordinate extends Equatable {
  final double latitude;
  final double longitude;

  const Coordinate({required this.latitude, required this.longitude});

  Map<String, double> toJson() => {'lat': latitude, 'lng': longitude};

  @override
  List<Object?> get props => [latitude, longitude];
}

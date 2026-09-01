import 'package:equatable/equatable.dart';

class const Coordinate({required this.latitude, required this.longitude})
    extends Equatable {
  final double latitude;
  final double longitude;

  Map<String, double> toJson() => {'lat': latitude, 'lng': longitude};

  @override
  List<Object?> get props => [latitude, longitude];
}

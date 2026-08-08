import 'package:equatable/equatable.dart';

class CurrentLocation extends Equatable {
  const CurrentLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

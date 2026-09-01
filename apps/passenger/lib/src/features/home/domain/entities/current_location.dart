import 'package:equatable/equatable.dart';

class const CurrentLocation({required this.latitude, required this.longitude})
    extends Equatable {
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

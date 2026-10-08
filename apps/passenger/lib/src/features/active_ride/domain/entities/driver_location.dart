import 'package:equatable/equatable.dart';

final class const DriverLocation({
  required final double latitude,
  required final double longitude,
  final DateTime? observedAt,
}) extends Equatable {
  @override
  List<Object?> get props => [latitude, longitude, observedAt];
}

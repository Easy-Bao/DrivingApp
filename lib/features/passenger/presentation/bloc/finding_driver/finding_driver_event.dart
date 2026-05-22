import 'package:equatable/equatable.dart';
import 'package:BaoRide/core/models/driver/driver_model.dart';

abstract class FindingDriverEvent extends Equatable {
  const FindingDriverEvent();

  @override
  List<Object?> get props => [];
}

class SearchDriversEvent extends FindingDriverEvent {
  final double lat;
  final double lng;

  const SearchDriversEvent({required this.lat, required this.lng});

  @override
  List<Object?> get props => [lat, lng];
}

class SelectDriverEvent extends FindingDriverEvent {
  final DriverModel driver;

  const SelectDriverEvent({required this.driver});

  @override
  List<Object?> get props => [driver];
}

class CancelSearchEvent extends FindingDriverEvent {}

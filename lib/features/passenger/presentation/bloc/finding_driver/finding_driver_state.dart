import 'package:equatable/equatable.dart';
import 'package:BaoRide/core/models/driver/driver_model.dart';

abstract class FindingDriverState extends Equatable {
  const FindingDriverState();

  @override
  List<Object?> get props => [];
}

class FindingDriverInitial extends FindingDriverState {}

class FindingDriverSearching extends FindingDriverState {}

class FindingDriverResults extends FindingDriverState {
  final List<DriverModel> drivers;

  const FindingDriverResults({required this.drivers});

  @override
  List<Object?> get props => [drivers];
}

class FindingDriverSelected extends FindingDriverState {
  final DriverModel selectedDriver;

  const FindingDriverSelected({required this.selectedDriver});

  @override
  List<Object?> get props => [selectedDriver];
}

class FindingDriverCanceled extends FindingDriverState {}

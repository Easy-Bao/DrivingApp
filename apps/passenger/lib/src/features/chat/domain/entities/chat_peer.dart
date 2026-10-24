import 'package:equatable/equatable.dart';

class const ChatPeer({
  required this.name,
  this.plate = '',
  this.vehicle = '',
  this.phone = '',
  this.contactAllowed = false,
}) extends Equatable {
  final String name;
  final String phone;
  final bool contactAllowed;
  bool get canCall => contactAllowed && phone.trim().isNotEmpty;
  final String plate;
  final String vehicle;
  String get vehicleLabel =>
      [plate, vehicle].where((value) => value.isNotEmpty).join(' | ');
  @override
  List<Object?> get props => [name, plate, vehicle, phone, contactAllowed];
}

import 'package:equatable/equatable.dart';

class const ChatPeer({required this.name, this.plate = '', this.vehicle = ''})
    extends Equatable {
  final String name;
  final String plate;
  final String vehicle;
  String get vehicleLabel =>
      [plate, vehicle].where((value) => value.isNotEmpty).join(' | ');
  @override
  List<Object?> get props => [name, plate, vehicle];
}

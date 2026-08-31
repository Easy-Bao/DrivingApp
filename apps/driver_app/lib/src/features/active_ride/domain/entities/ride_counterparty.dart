import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

class RideCounterparty extends Equatable {
  const RideCounterparty({
    required this.userId,
    required this.name,
    required this.phone,
    required this.contactAllowed,
  });

  factory RideCounterparty.fromJson(Map<String, dynamic> json) {
    return RideCounterparty(
      userId: SafeParse.toStringValue(json['user_id'] ?? json['userId']).trim(),
      name: SafeParse.toStringValue(json['name']).trim(),
      phone: SafeParse.toStringValue(json['phone']).trim(),
      contactAllowed: json['contact_allowed'] == true,
    );
  }

  final String userId;
  final String name;
  final String phone;
  final bool contactAllowed;

  @override
  List<Object?> get props => [userId, name, phone, contactAllowed];
}

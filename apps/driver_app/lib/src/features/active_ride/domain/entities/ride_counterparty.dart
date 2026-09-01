import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

final class const RideCounterparty({
  required final String userId,
  required final String name,
  required final String phone,
  required final bool contactAllowed,
}) extends Equatable {
  factory RideCounterparty.fromJson(Map<String, dynamic> json) {
    return RideCounterparty(
      userId: SafeParse.toStringValue(json['user_id'] ?? json['userId']).trim(),
      name: SafeParse.toStringValue(json['name']).trim(),
      phone: SafeParse.toStringValue(json['phone']).trim(),
      contactAllowed: json['contact_allowed'] == true,
    );
  }

  @override
  List<Object?> get props => [userId, name, phone, contactAllowed];
}

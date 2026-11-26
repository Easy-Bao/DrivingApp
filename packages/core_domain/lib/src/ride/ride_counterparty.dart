import 'package:core_domain/src/internal/json_parsing.dart';
import 'package:equatable/equatable.dart';

final class const RideCounterparty({
  required final String userId,
  required final String name,
  required final String phone,
  required final bool contactAllowed,
}) extends Equatable {
  factory fromJson(Map<String, dynamic> json) {
    final {
      'user_id': rawUserId,
      'name': rawName,
      'phone': rawPhone,
      'contact_allowed': rawContactAllowed,
    } = _canonicalPayload(
      json,
    );

    return RideCounterparty(
      userId: readStringValue(rawUserId).trim(),
      name: readStringValue(rawName).trim(),
      phone: readStringValue(rawPhone).trim(),
      contactAllowed: rawContactAllowed == true,
    );
  }

  @override
  List<Object?> get props => [userId, name, phone, contactAllowed];
}

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'user_id': json['user_id'] ?? json['userId'],
  'name': json['name'],
  'phone': json['phone'],
  'contact_allowed': json['contact_allowed'],
};

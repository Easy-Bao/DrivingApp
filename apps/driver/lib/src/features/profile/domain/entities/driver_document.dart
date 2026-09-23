import 'package:equatable/equatable.dart';

enum DriverDocumentType { driverLicense, vehicleRegistration }

extension DriverDocumentTypeValues on DriverDocumentType {
  String get queryValue => switch (this) {
    DriverDocumentType.driverLicense => 'driver_license',
    DriverDocumentType.vehicleRegistration => 'vehicle_registration',
  };

  String get label => switch (this) {
    DriverDocumentType.driverLicense => "Driver's license",
    DriverDocumentType.vehicleRegistration => 'Vehicle registration',
  };
}

class const DriverDocument({
  required this.id,
  required this.type,
  required this.status,
  required this.contentType,
}) extends Equatable {
  final int id;
  final DriverDocumentType type;
  final String status;
  final String contentType;

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    final rawType = json['document_type'] ?? json['documentType'];
    final type = switch (rawType) {
      'vehicle_registration' => DriverDocumentType.vehicleRegistration,
      _ => DriverDocumentType.driverLicense,
    };
    return DriverDocument(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      type: type,
      status: '${json['status'] ?? 'pending'}',
      contentType: '${json['content_type'] ?? json['contentType'] ?? ''}',
    );
  }

  @override
  List<Object> get props => [id, type, status, contentType];
}

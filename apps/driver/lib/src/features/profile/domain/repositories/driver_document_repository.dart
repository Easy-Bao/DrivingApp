import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverDocumentRepository {
  Future<Result<DriverDocument, Failure>> upload({
    required DriverDocumentType type,
    required List<int> bytes,
    required String contentType,
  });
}

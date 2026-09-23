import 'package:driver/src/features/profile/data/data_sources/driver_document_remote_data_source.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_document_repository.dart';
import 'package:foundation/foundation.dart';

final class DriverDocumentRepositoryImpl implements DriverDocumentRepository {
  const DriverDocumentRepositoryImpl(this._dataSource);

  final DriverDocumentRemoteDataSource _dataSource;

  @override
  Future<Result<DriverDocument, Failure>> upload({
    required DriverDocumentType type,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      return Ok(
        await _dataSource.upload(
          type: type,
          bytes: bytes,
          contentType: contentType,
        ),
      );
    } catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: 'Document upload is temporarily unavailable.',
          networkMessage:
              'Unable to upload the document. Check your connection.',
          timeoutMessage: 'Document upload timed out. Please try again.',
        ),
      );
    }
  }
}

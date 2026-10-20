import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_document_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

enum DocumentUploadStatus { idle, uploading, succeeded, failed }

class const DocumentUploadState({
  this.status = DocumentUploadStatus.idle,
  this.document,
  this.message,
}) extends Equatable {
  final DocumentUploadStatus status;
  final DriverDocument? document;
  final String? message;

  bool get isUploading => status == DocumentUploadStatus.uploading;

  @override
  List<Object?> get props => [status, document, message];
}

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  DocumentUploadCubit(this.repository) : super(const DocumentUploadState());

  final DocumentRepository repository;

  Future<void> submit({
    required DriverDocumentType type,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (isClosed || state.isUploading) return;
    emit(const DocumentUploadState(status: DocumentUploadStatus.uploading));

    try {
      final result = await repository.upload(
        type: type,
        bytes: bytes,
        contentType: contentType,
      );
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          DocumentUploadState(
            status: DocumentUploadStatus.failed,
            message: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (document) => emit(
          DocumentUploadState(
            status: DocumentUploadStatus.succeeded,
            document: document,
          ),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        DocumentUploadState(
          status: DocumentUploadStatus.failed,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  void reset() {
    if (!isClosed) emit(const DocumentUploadState());
  }
}

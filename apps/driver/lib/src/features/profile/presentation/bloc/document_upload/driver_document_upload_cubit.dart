import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_document_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

enum DriverDocumentUploadStatus { idle, uploading, succeeded, failed }

class const DriverDocumentUploadState({
  this.status = DriverDocumentUploadStatus.idle,
  this.document,
  this.message,
}) extends Equatable {
  final DriverDocumentUploadStatus status;
  final DriverDocument? document;
  final String? message;

  bool get isUploading => status == DriverDocumentUploadStatus.uploading;

  @override
  List<Object?> get props => [status, document, message];
}

class DriverDocumentUploadCubit extends Cubit<DriverDocumentUploadState> {
  DriverDocumentUploadCubit(this.repository)
    : super(const DriverDocumentUploadState());

  final DriverDocumentRepository repository;

  Future<void> submit({
    required DriverDocumentType type,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (isClosed || state.isUploading) return;
    emit(
      const DriverDocumentUploadState(
        status: DriverDocumentUploadStatus.uploading,
      ),
    );

    try {
      final result = await repository.upload(
        type: type,
        bytes: bytes,
        contentType: contentType,
      );
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          DriverDocumentUploadState(
            status: DriverDocumentUploadStatus.failed,
            message: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (document) => emit(
          DriverDocumentUploadState(
            status: DriverDocumentUploadStatus.succeeded,
            document: document,
          ),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        DriverDocumentUploadState(
          status: DriverDocumentUploadStatus.failed,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  void reset() {
    if (!isClosed) emit(const DriverDocumentUploadState());
  }
}

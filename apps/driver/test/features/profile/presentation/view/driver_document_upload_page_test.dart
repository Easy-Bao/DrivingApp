import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_document_repository.dart';
import 'package:driver/src/features/profile/presentation/bloc/document_upload/driver_document_upload_cubit.dart';
import 'package:driver/src/features/profile/presentation/view/driver_document_upload_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:image_picker/image_picker.dart';

class _FakeDriverDocumentRepository implements DriverDocumentRepository {
  int uploadCount = 0;

  @override
  Future<Result<DriverDocument, Failure>> upload({
    required DriverDocumentType type,
    required List<int> bytes,
    required String contentType,
  }) async {
    uploadCount++;
    return Ok(
      DriverDocument(
        id: 1,
        type: type,
        status: 'pending',
        contentType: contentType,
      ),
    );
  }
}

class _CountingXFile extends XFile {
  _CountingXFile(Uint8List bytes)
    : super.fromData(bytes, name: 'license.png', mimeType: 'image/png');

  int readCount = 0;

  @override
  Future<Uint8List> readAsBytes() {
    readCount++;
    return super.readAsBytes();
  }
}

void main() {
  testWidgets('previews a captured photo before upload', (tester) async {
    final repository = _FakeDriverDocumentRepository();
    final cubit = DriverDocumentUploadCubit(repository);
    addTearDown(cubit.close);
    final photo = _CountingXFile(
      Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47]),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: BlocProvider.value(
          value: cubit,
          child: DriverDocumentUploadPage(pickPhoto: () async => photo),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('driver-document-choose-photo')),
    );
    await tester.pumpAndSettle();
    expect(photo.readCount, 1);
    expect(
      find.byKey(const ValueKey('driver-document-photo-preview')),
      findsOneWidget,
    );
    expect(repository.uploadCount, 0);

    await tester.pump();
    expect(photo.readCount, 1);
    await tester.tap(find.byKey(const ValueKey('driver-document-submit')));
    await tester.pumpAndSettle();
    expect(repository.uploadCount, 1);
    expect(photo.readCount, 1);
  });
}

import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:driver/src/features/profile/domain/repositories/document_repository.dart';
import 'package:driver/src/features/profile/presentation/bloc/document_upload/document_upload_cubit.dart';
import 'package:driver/src/features/profile/presentation/pages/document_upload_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class _FakeDocumentRepository implements DocumentRepository {
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
  _CountingXFile(super.bytes)
    : super.fromData(name: 'license.png', mimeType: 'image/png');

  int readCount = 0;

  @override
  Future<Uint8List> readAsBytes() {
    readCount++;
    return super.readAsBytes();
  }
}

void main() {
  testWidgets('previews a captured photo before upload', (tester) async {
    final repository = _FakeDocumentRepository();
    final cubit = DocumentUploadCubit(repository);
    addTearDown(cubit.close);
    final photo = _CountingXFile(
      Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47]),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider.value(
          value: cubit,
          child: DocumentUploadPage(pickPhoto: () async => photo),
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

  testWidgets('switches document type cleanly and disables platform splashes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeDocumentRepository();
    final cubit = DocumentUploadCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: BlocProvider.value(
          value: cubit,
          child: const DocumentUploadPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final registrationOption = find.byKey(
      const ValueKey<String>('driver-document-type-registration'),
    );
    await tester.ensureVisible(registrationOption);
    await tester.pumpAndSettle();
    await tester.tap(registrationOption);
    await tester.pumpAndSettle();

    final chooseFinder = find.byKey(
      const ValueKey('driver-document-choose-photo'),
    );
    await tester.ensureVisible(chooseFinder);
    final chooseButton = tester.widget<OutlinedButton>(chooseFinder);
    expect(chooseButton.style?.enableFeedback, isFalse);
    expect(chooseButton.style?.splashFactory, NoSplash.splashFactory);

    final submitFinder = find.byKey(const ValueKey('driver-document-submit'));
    await tester.ensureVisible(submitFinder);
    final submitButton = tester.widget<FilledButton>(submitFinder);
    expect(submitButton.style?.enableFeedback, isFalse);
    expect(submitButton.style?.splashFactory, NoSplash.splashFactory);
    expect(tester.takeException(), isNull);
  });
}

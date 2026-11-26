import 'dart:convert';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/profile/presentation/widgets/profile_avatar.dart';

void main() {
  // 1x1 transparent PNG
  const validPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  Uint8List? extractMemoryImageBytes(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;
    if (provider is ResizeImage) {
      final inner = provider.imageProvider;
      if (inner is MemoryImage) return inner.bytes;
    }
    if (provider is MemoryImage) return provider.bytes;
    return null;
  }

  testWidgets(
    'ProfileAvatar reuses cached decoded bytes across parent rebuilds',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: const Scaffold(
            body: ProfileAvatar(initials: 'JD', imageData: validPngBase64),
          ),
        ),
      );

      final firstBytes = extractMemoryImageBytes(tester);
      expect(firstBytes, isNotNull);
      expect(firstBytes, base64Decode(validPngBase64));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: const Scaffold(
            body: ProfileAvatar(initials: 'JX', imageData: validPngBase64),
          ),
        ),
      );

      final secondBytes = extractMemoryImageBytes(tester);
      expect(identical(firstBytes, secondBytes), isTrue);
    },
  );

  testWidgets('ProfileAvatar falls back to initials for malformed base64', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: const Scaffold(
          body: ProfileAvatar(initials: 'AB', imageData: '%%%not-base64%%%'),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('AB'), findsOneWidget);
  });
}

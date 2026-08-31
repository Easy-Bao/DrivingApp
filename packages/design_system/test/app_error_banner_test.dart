import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('offers one accessible retry action', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: AppErrorBanner(
          message: 'The account could not be loaded.',
          onRetry: () => retryCount++,
        ),
      ),
    );

    expect(find.text('The account could not be loaded.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('Retry'));
    expect(retryCount, 1);
  });
}
